# Auditoria visual — telas fora do contador de vida (2026-09-21)

> **Documentação de apoio, não autoritativa.** Não é lida por gates, digest de UI nem manifesto. O contrato oficial continua sendo `docs/project_logic_contracts.json` e a fila em `docs/execution/`.
>
> Data: 2026-09-21 · Commit auditado: `d26f23a16` · Branch: `codex/free-beta-release-candidate-2026-07-17` · Bruto: [`audit.json`](audit.json) · Régua usada: [`regua-contador-hub.png`](regua-contador-hub.png) e `docs/design/life-counter-prototype/`.

## Pergunta

"No contador de vida estamos tendo todo esse cuidado no layout. As demais telas do app estão nesse mesmo nível?"

**Resposta: não.** As outras telas ficaram entre 4 e 5 de 10 contra a régua do contador, e o nível dominante é "formulário".

## Método

- 8 áreas. Cada uma teve um **auditor** (diretor de arte) e um **revisor cético** que abriu as mesmas capturas e contestou as notas nas duas direções.
- Os agentes abriram as capturas PNG reais (mobile 390 px primeiro) antes de ler o código. Somente leitura: nada foi editado, nenhum app foi rodado.
- Mais 3 agentes: sistema de design compartilhado, processo de QA e crítico de completude. Total 19 agentes, nenhum falhou.
- Rubrica 0–5 por critério (5 = nível do contador, 3 = correto mas genérico, 1 = formulário/feio): objetos visuais, hierarquia, tipografia, material, identidade MTG, respiro, estados, primeira impressão.
- Capturas de `docs/qa/ui-live/current/` e `app/test/ui/goldens/runtime/web_mobile/`.

## Errata e confiabilidade

Leia antes de usar qualquer `arquivo:linha` deste relatório.

- **Correção ao agente de sistema de design.** Ele afirmou que o protótipo do contador só existia num scratchpad volátil fora do repo. Está em `docs/design/life-counter-prototype/` (pasta não commitada em 2026-09-21). A conclusão dele se mantém: nada dessa linguagem existe em `app/lib`.
- **Os revisores conferiram 92 afirmações de código dos auditores: 80 conferem, 12 não.** As 12 estão listadas abaixo. As notas visuais não dependem delas (foram dadas pelo olho, nas capturas), mas confira a linha antes de abrir uma task a partir de um cheiro de formulário.
- As notas são julgamento de agentes sobre capturas de fixture, não medição. Servem para ordenar o trabalho, não como métrica de produto.

**Afirmações que não conferem**

- [decks-core] Importar e Gerador não têm nenhum texto serifado ('Zero Fraunces na tela inteira', 'sem um pixel de serifada') — Falso. deck_import_screen.dart:771 usa titleLarge e deck_generate_screen.dart:1062 usa headlineSmall; ambos são mapeados para Fraunces no tema (app_theme.dart:517-527). O golden deck_generate_empty.png mostra 'Gerar Deck' serifado. O auditor só viu capturas roladas para baixo do cabeçalho. A crítica de fundo (um único título serifado, zero contraste de escala, AppBar em Inter) continua válida, mas tipografia dessas telas é 2, não 1.
- [decks-core] deck_generate_screen.dart:1204/1210 — helperText do comandante trunca com reticências — Defasado. O código atual tem outro texto e helperMaxLines: 3 (linha 1212); o golden de 09/09 mostra o helper quebrando em 3 linhas sem truncar. A truncagem só existe na captura Android de 02/08. O 'ganho rápido' correspondente já está feito.
- [decks-core] Modal Novo Deck: 'primeira coisa que o olho vê é um contorno vermelho — o ponto focal da tela é um erro' — Artefato de captura. nameError nasce null (deck_list_screen.dart:116) e só é preenchido após tentativa de envio; core_05 chama-se literalmente 'deck_inline_validation' e o golden também foi tirado nesse estado. Ao abrir, o modal não tem erro. Não muda o veredito (continua formulário em Dialog), mas esse problema específico não é do design.
- [deck-workshop] 'Desfazer', ação de segurança importante, vive num toast que desaparece. — Incompleto. Existe um desfazer persistente no histórico: OutlinedButton 'Desfazer aplicação', condicionado a event.canRollback, em deck_workshop_tab.dart:581-600. Aparece na captura deck_workshop_06.
- [deck-workshop] '~55% da tela é preto vazio' na mão de exemplo, tratado como defeito do design. — É artefato do harness. O widget é montado sozinho em Scaffold+SingleChildScrollView (deck_workshop_visual_runtime_proof_test.dart:826-842). Em produção fica embutido em abas com mais conteúdo (deck_details_overview_tab.dart:327 e deck_details_screen.dart:924).
- [binder-scanner] Não existe captura do scanner nem do fichário populado no repositório. — Para o scanner, a afirmação é verdadeira: find por '*scan*.png' em docs/qa e app/test retorna vazio. Para o fichário populado, é falsa: existem docs/qa/ui-live/current/ux-pack-01-completion-web/binder_physical_identity.png, binder_editor_identity.png e binder_add_editor_identity.png.
- [social-trade] user_profile_screen.dart:319-320 e user_search_screen.dart:233-234 — avatar é CircleAvatar com inicial — Confere só em parte. Os dois usam backgroundImage: CachedNetworkImageProvider(user.avatarUrl) quando avatarUrl existe (user_profile :319-324, user_search :233-238, message_inbox :186-191). A inicial é o fallback, e o fixture não tem avatarUrl. Já em trade_detail_screen.dart:316 e trade_inbox_screen.dart:350 o avatar é sempre a inicial: esses dois nunca consultam avatarUrl.
- [perfil-auth-comercial] AppStatePanel: 'Bloco não é centralizado verticalmente: ~230px vazios embaixo' — Falso. app/lib/core/widgets/app_state_panel.dart:90-92 usa SingleChildScrollView > ConstrainedBox(minHeight) > Center. Nas capturas as hairlines ficam em y=287/612 (no_results), 296/603 (offline) e 277/622 (permission_denied). Todas têm ponto médio 449,5, exatamente o centro do corpo (55..844). Há ~240px vazios em cima também, então o bloco está centralizado. Procedem as duas hairlines soltas e a ilustração com alpha 0,08–0,30 (linhas 244-275).
- [perfil-auth-comercial] Nome serifado truncado ('Marina — Arquivista de Co…', 'Aurora — Pilota Azorius e organiza…') tratado como defeito do design — É fixture de estresse deliberado. Os display_name têm 45–50 caracteres em app/test/features/profile/profile_screen_test.dart:34 e app/test/features/social/screens/user_profile_screen_responsive_test.dart:18. Com nome normal ('Guardião do Fichário', pack 08) não há truncamento. Elipse em duas linhas para um nome de 50 caracteres é comportamento correto, e não deveria ter custado ponto.
- [battle] O tema já tem lifeCounterWinnerGradient (app_theme.dart:109), sem uso no painel terminal. — O token existe na linha 109, mas não é usado em nenhum lugar do app e é um arco-íris pastel fora da paleta. A recomendação de usá-lo é ruim, embora o diagnóstico do fim de partida esteja certo.
- [battle] O Battle Lab tem 2 ocorrências de gradiente/sombra, e o estilo display Fraunces aparece 3 vezes em ~10,9 mil linhas. — A contagem está imprecisa. battle_replays_screen.dart tem 0 gradientes e 3 BoxShadow. Os estilos display/headline aparecem 4 vezes nos três arquivos, que somam 10.898 linhas. A conclusão de que quase não há material nem tipografia display se mantém.
- [battle] Na versão web do espectador, a mesa inteira são dois blocos de chips. — É artefato do fixture. battle_live_visual_runtime_proof_test.dart:489-502 envia só battlefield_count, sem a lista battlefield. O código em :1063-1070 mostra as zonas com cartas quando as listas chegam, como se vê na captura mobile.

## Nota por área (10 = nível do contador)

| Área | Auditor | Revisor | Nível revisado | Auditor foi | Capturas |
|---|---|---|---|---|---|
| Home, onboarding, notificações, splash | 4 | **4.5** | correto, genérico | justo | 12 |
| Decks: lista, detalhe, criar, importar | 4.5 | **4.5** | formulário | justo | 12 |
| Oficina de deck: gerador IA, otimização, trocas pareadas, mão de exemplo, histórico | 3.5 | **4** | formulário | justo | 18 |
| Cartas e catálogo: detalhe da carta, busca, coleções/sets, impressões | 4.5 | **5** | correto, genérico | justo | 22 |
| Fichário/coleção: importação em lote, editor, scanner | 3.5 | **4** | formulário | justo | 12 |
| Social: marketplace, trades, mensagens, comunidade, perfis públicos, busca de usuários | 4 | **4** | formulário | justo | 30 |
| Perfil, autenticação, planos/checkout, legal, overlays críticos | 4 | **4.5** | correto, genérico | duro-demais | 39 |
| Battle: coach, mesa ao vivo, jogar vs IA, replay, pós-jogo | 3.5 | **4.5** | formulário | justo | 33 |

## Os 3 achados estruturais

Os três primeiros pontos foram conferidos manualmente no repo depois da auditoria.

1. **A gramática do contador não está em código compartilhado.** Nenhum arquivo em `app/lib` contém os azulejos, os numerais gigantes ou o estado dentro do objeto. Ela vive no protótipo HTML (`docs/design/life-counter-prototype/`, não commitado em 2026-09-21) e na skin CSS do WebView Lotus (`lotus_visual_skin.dart`).
2. **O próprio tema proíbe essa linguagem.** `app/lib/core/theme/app_theme.dart:18` diz "Gradients only for hero sections and primary buttons" e `cardGradient` (linhas 183–188) é "intentionally flat". As outras telas são chapadas por regra, não por descuido.
3. **Beleza não é cobrada fora do contador.** O gate de `attractiveness` em `app/tool/ui_runtime_evidence.dart:729-738` só exige `status == 'pass'` e uma nota não vazia, preenchidos pelo próprio agente.

### Sistema de design (agente)

Não, o cuidado visual do contador não está no mesmo nível no resto do app. A linguagem da imagem de referência não pode ser herdada hoje, porque não existe em nenhum token ou widget Flutter do repositório. Investigação feita só por leitura de código, sem rodar o app.

**Onde a linguagem do contador vive hoje**
1. **Protótipo HTML/CSS fora do repo.** A grade de azulejos com PASSAR A VEZ, COROA e INICIATIVA "sem dono" só aparece no scratchpad volátil de outra sessão (`mesa-brewtact.html`, variante `azulejos-vivos`). As buscas por "passar a vez", "azulejo" e "mesa-brewtact" no repo não retornam nada. A busca no histórico git por "PASSAR A VEZ" também não retorna nada.
2. **Skin CSS do WebView.** O contador no repo é o bundle Lotus, estilizado por CSS dentro de uma string Dart (`lotus_visual_skin.dart`, 3616 linhas, 57 gradientes, Fraunces via @font-face). Widgets Flutter não conseguem herdar CSS.
3. **Sheets nativos do próprio contador.** `life_counter/*_sheet.dart` é exatamente o "estilo configurações" que o dono rejeita: 48 FilledButton, 28 OutlinedButton, 15 showModalBottomSheet e 25 Chips. `_SectionCard` (caixa `surfaceElevated` com outline, título e subtítulo) aparece copiado 6 vezes.

**O que já é compartilhado**
- A paleta do protótipo é idêntica a `AppTheme`: obsidian `#0B0D12`/`#151821`, brass `#E0A93B`/`#C58B2A`/`#8E641B`, ivory `#F3EFE3`.
- As fontes Inter e Fraunces também já são as do `AppTheme`.

**O que não existe em lugar nenhum do Flutter**
- O material do tile (gradiente 160°, inset highlight, sombra de 8–10px, raio 22).
- O tile aceso com cor de significado, o herói dourado e o tile tracejado "livre".
- Numeral Fraunces de 56/70px com lining-nums.
- A grade em que tudo fica visível, o backdrop da mesa viva desfocada com um único ✕ e o estado dentro do objeto.

**O que o resto do app usa**
- `core/widgets` tem 12 arquivos, nenhum deles tile, numeral ou herói, e o contador não importa nenhum.
- As features definem 161 classes privadas `_Card`/`_Tile`/`_Panel`/`_Section`, cada tela reinventando a sua.
- Fora do contador há 65 FilledButton, 62 OutlinedButton, 51 ElevatedButton, 114 TextButton, 67 campos de texto, 30 Dropdown, 48 showDialog e 32 AlertDialog.
- Há só 2 textos de 32px ou mais fora do contador.

**As regras do design system proíbem a linguagem do contador**
- `app_theme.dart` linhas 14–18 e 161–188 dizem "Gradients only for hero sections and primary buttons" e definem `cardGradient` como "intentionally flat".
- Dos 62 tokens `lifeCounter*` em `AppTheme`, 52 não têm nenhum uso em `lib` (herança do contador nativo antigo).

**Uso da fonte display fora do contador.** A Fraunces está registrada em `pubspec.yaml`, com o asset em `assets/lotus/fonts/Fraunces.ttf` (mora dentro da pasta do bundle Lotus). Está exposta como `AppTheme.displayFontFamily` e mapeada no textTheme para display*, headline* (22–30px) e titleLarge (18px).

Fora do contador há 24 referências diretas a `displayFontFamily` em 11 arquivos:
- `deck_list_screen.dart` 6, `profile_screen.dart` 4 e `community_screen.dart` 4.
- `user_profile_screen.dart` 2.
- `trade_matches_screen.dart`, `collection_screen.dart`, `card_search_screen.dart`, `deck_commander_selector.dart`, `onboarding_core_flow_screen.dart` e `splash_screen.dart` 1 cada.
- `core/widgets/app_state_panel.dart` 1.

Há também cerca de 25 usos de `textTheme.display*`/`headline*`: decks 7, home 4, profile 3, battle 3, social 2, commercial 2, auth 2.

Em todos os casos a serifada é só fonte de título, entre 13 e 18px (`fontLg+1`, `fontLg`, `fontSm+1`, `fontMd`). O único caso de 32px ou mais é a splash (`fontDisplay+2`, 34px). Não existe nenhum numeral serifado gigante como objeto visual (56/70px) fora do contador. No Flutter do próprio contador também não existe, porque os numerais grandes vivem no CSS do WebView e no protótipo HTML. Os tokens `fontLifeCounter*` (42 a 246px) estão declarados e quase todos sem uso.

**Primitivas antigas por feature**

| Feature | Contagem |
|---|---|
| decks (40 arquivos, 35.002 linhas) | TextButton 36, ElevatedButton 24, showDialog 22, TextField 16, OutlinedButton 16, ListTile 15, FilledButton 12, DropdownButton 12, AlertDialog 10, Chips 5, Card 4, showModalBottomSheet 4, ExpansionTile 3, SwitchListTile 1. Gradientes 5, caixas chapadas surfaceSlate/Elevated 58, classes privadas de card/painel 41. |
| battle (16 arquivos, 16.825 linhas) | TextButton 19, FilledButton 17, OutlinedButton 14, TextField 9, showDialog 7, DropdownButton 6, AlertDialog 5, ExpansionTile 4, SegmentedButton 1, ListTile 1. Gradientes 2, caixas chapadas 35, classes privadas 29. |
| binder (8 arquivos, 8.443 linhas) | OutlinedButton 13, Chips 11, TextButton 9, FilledButton 7, TextField 6, DropdownButton 6, ElevatedButton 4, SwitchListTile 3, showDialog 3, AlertDialog 3, Card 2, showModalBottomSheet 1. Gradientes 1, BoxShadow 0, caixas chapadas 14. |
| profile (2 arquivos, 2.446 linhas) | TextButton 15, TextFormField 7, FilledButton 7, showDialog 6, AlertDialog 6, TextField 3, OutlinedButton 3, DropdownButton 2. Gradientes 1, BoxShadow 0. |
| auth (13 arquivos) | TextFormField 9, TextButton 9, FilledButton 4, OutlinedButton 2, ListTile 1. Gradientes 6, BoxShadow 4. A splash é o único lugar fora do contador com Fraunces de 32px ou mais. |
| trades (7 arquivos, 5.931 linhas) | ElevatedButton 8, TextButton 8, TextField 4, showDialog 3, AlertDialog 3, Card 2, TabBar 2, OutlinedButton 2, FilledButton 2. Gradientes 0, BoxShadow 0, caixas chapadas 13. |
| community (3 arquivos, 3.785 linhas) | ElevatedButton 6, ListTile 3, TextField 3, TabBar 2, Card 1, Chips 1, DropdownButton 1, AlertDialog 1. Gradientes 3, caixas chapadas 12. |
| social (4 arquivos, 3.033 linhas) | ListTile 4, FilledButton 4, Card 3, TextButton 3, TextField 2, TabBar 2, showDialog 2, AlertDialog 2, showModalBottomSheet 1. Gradientes 0, BoxShadow 0. |
| retention (3 arquivos, 2.844 linhas) | TextField 4, Chips 3, TextButton 3, ElevatedButton 2, OutlinedButton 1, FilledButton 1. Gradientes 1, caixas chapadas 11. |
| cards / collection / scanner / messages / commercial / notifications | cards: TextField 1, botões 6, showDialog 2, showModalBottomSheet 1. collection: ListTile 2, TextField 1, Chips 1, TabBar 1. scanner: botões 4, TextField 1. messages: ListTile 3, TextField 1, AlertDialog 1. commercial: ElevatedButton 3, TextButton 3, OutlinedButton 2, AlertDialog 1. notifications: TextButton 1. Somados, têm 8 gradientes. |
| home sem o contador (home_screen.dart 2.227 linhas + onboarding 1.526 linhas) | home_screen: FilledButton 5, OutlinedButton 3, TextButton 2, showModalBottomSheet 1. onboarding: FilledButton 2, TextButton 3, Chips 1. |
| contador: home/life_counter + home/lotus (para comparação) | FilledButton 50, OutlinedButton 28, TextButton 18, showModalBottomSheet 15, Chips 25, TextField 8, switches 4, showDialog 3, AlertDialog 3. Os sheets nativos do contador no repo são a maior concentração de "estilo configurações" do app. A linguagem premium está só no CSS do WebView e no protótipo HTML. |
| TOTAL fora do contador | FilledButton 65, OutlinedButton 62, ElevatedButton 51, TextButton 114, TextField 51 + TextFormField 16, DropdownButton 30, showDialog 48, AlertDialog 32, showModalBottomSheet 9. Textos com fontSize de 32 ou mais: 2 (splash e home_screen). |

**O que extrair**

- Trazer a referência para o repo. O protótipo /private/tmp/claude-501/-Users-desenvolvimentomobile-Documents-rafa-mtg-mtgia/d32b60eb-412a-40fd-87e7-6a688b3766e6/scratchpad/mesa-brewtact.html e a pasta design/azulejos-vivos/ ficam em diretório temporário e podem sumir. Versionar, por exemplo, em docs/design/contador-azulejos/, junto com /private/tmp/.../c6c20cac-53ba-46a9-bda2-85f860cc4f8f/scratchpad/ref/contador_hub_referencia.png como régua oficial.
- Revogar as regras que proíbem essa linguagem em app/lib/core/theme/app_theme.dart e em docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md. São as linhas 14–18 ("Gradients only for hero sections and primary buttons"), 161–163 e 183–188 (cardGradient "intentionally flat"), além de cardTheme com elevation 0 e sem sombra (linhas 622–630).
- Criar tokens de material em app/lib/core/theme/app_theme.dart. tileGradient: 160°, rgba(41,48,65,.88) → rgba(21,24,33,.95). tileLitGradient(cor, cor2): clareia 22% → cor → escurece 34%. heroBrassGradient: #F4CB6C → brass400 → brass500. tileShadows: inset highlight + 0 8px 18px preto 45%, e 0 10px 22px com anel de 3px obsidian para lit/herói. radiusTile = 22. tileDashedBorder: brass400 a 50%.
- Criar tokens de cor com significado em app/lib/core/theme/app_theme.dart. O teste app/test/core/theme/app_theme_token_usage_test.dart proíbe cor local. As cores são noite #2B3274/#12163F, dia #3E8FC9/#E0A24A, plano #5B3A8C/#23163F, perigo #B5402B e livre #2B2114/#1A1610. Aproveitar para remover os 52 tokens lifeCounter*/life* sem nenhum uso em app/lib (linhas 66–142, 297–302 e 316–329).
- Criar uma escala tipográfica de objeto como ThemeExtension, em app/lib/core/theme/app_numeral_theme.dart. numeralTile: Fraunces 700, 56px, height 0.8, FontFeature.liningFigures. numeralHero: 70px. stateDisplay: Fraunces 700, 17px. heroName: Fraunces 700, 30px. tileLabel: Inter 800, 11.5px, tracking .085em, maiúsculas. tileSub: Inter 700, 11px. Mover o asset da fonte de app/assets/lotus/fonts/Fraunces.ttf para app/assets/fonts/, para não depender do bundle Lotus.
- Novo widget app/lib/core/widgets/app_tile.dart. É a primitiva central (AppTile), com variantes quiet, lit(cor), hero, livre (tracejado), quietDanger e armed. Tem slots de ícone grande (34px com drop-shadow), rótulo embaixo, estado no canto superior direito (o estado fica dentro do objeto), numeral e miniatura. Aplica escala .97 no toque e opacidade .38 quando desabilitado. Substitui as 161 classes privadas _*Card/_*Tile/_*Panel das features.
- Novo widget app/lib/core/widgets/app_numeral.dart. É o numeral serifado gigante como objeto ("2", "4", "40"), com sombra e lining-nums, para contagens de deck, preço, vitórias e quantidade de cartas.
- Novo widget app/lib/core/widgets/app_tile_board.dart. É a grade de azulejos por linhas com flex (f1/f2) e gap de 8, tudo visível de uma vez, sem scroll nem aninhamento, com largura máxima de 780 e respeito à safe area. Usar ResponsivePageFrame (app/lib/core/widgets/responsive_page_frame.dart) como moldura.
- Novo widget app/lib/core/widgets/app_tile_overlay.dart. Tem o fundo vivo escurecido (radial rgba(11,13,18,.42→.78), BackdropFilter blur 3 e dessaturação) e um único ✕ circular com aro brass. É o substituto oficial de showModalBottomSheet, showDialog e AlertDialog. Fora do contador são 9 + 48 + 32 ocorrências, com prioridade para decks (22 showDialog, 10 AlertDialog), battle (7/5) e profile (6/6).
- Novo widget app/lib/core/widgets/app_hero_tile.dart. É o herói dourado: numeral à esquerda, divisor, rótulo, nome em Fraunces 30px, trilha de pips coloridos e botão circular escuro com seta brass. Dá a cada tela uma ação principal clara e substitui os botões largos (51 ElevatedButton e 65 FilledButton fora do contador).
- Novos widgets de escolha como objeto visual em app/lib/core/widgets/. layout_miniature.dart é a miniatura do layout da mesa e o modelo para miniaturas de deck, binder e formato. state_tiles.dart tem o tile céu dia/noite, o tile coroa e o tile iniciativa. Substituem SwitchListTile e switches (binder 3, decks 1), os 30 DropdownButton, o SegmentedButton e a sopa de chips (binder 11, decks 5).
- Migrar primeiro os sheets nativos do próprio contador para essas primitivas. Hoje eles contradizem a régua. Os 6 `_SectionCard` duplicados estão em life_counter_native_commander_damage_sheet.dart, _game_timer_sheet.dart, _player_appearance_sheet.dart, _player_state_sheet.dart, _history_sheet.dart e _turn_tracker_sheet.dart. Incluir também _settings_sheet.dart (_SettingsSection e _SettingEntryTile), _game_modes_sheet.dart e _set_life_sheet.dart, todos em app/lib/features/home/life_counter/.
- Ordem sugerida para o resto do app, pela densidade de primitivas de formulário. (1) app/lib/features/decks: deck_list_screen.dart, deck_details_screen.dart e widgets/deck_optimize_dialogs.dart. (2) app/lib/features/battle. (3) app/lib/features/binder. (4) app/lib/features/profile/profile_screen.dart. (5) app/lib/features/home/home_screen.dart e onboarding_core_flow_screen.dart. (6) trades, community e social, que têm 0 a 3 gradientes e nenhuma sombra.
- Criar um guarda de regressão no molde de app/test/core/theme/app_theme_token_usage_test.dart. O teste falha quando uma feature usa SwitchListTile, DropdownButton, AlertDialog ou showModalBottomSheet fora de uma lista de exceções. Assim a régua vira contrato e deixa de depender de revisão manual.

### Processo de QA (agente)

Não, o cuidado não está no mesmo nível. O restante do app tem um processo de evidência visual rigoroso em forma (3 níveis, 439-453 capturas, digest, hashes, 10 critérios incluindo "atratividade"), mas a beleza ali é um item auto-atestado por agente com "pass" + nota livre, aplicado de uma vez só ao app inteiro, que nunca gerou um finding bloqueante e cuja própria nota admite dívida de polish. O que é de fato cobrado nas outras telas é posição, estados, overflow, responsividade e acessibilidade. No contador, a beleza é critério de aceite explícito, julgado a olho, contra benchmark formal (Lotus, 10 capturas oficiais, side-by-side, DoD de "clone e não interpretação"), com 41% dos arquivos de teste do app e docs próprios de sprint e "perfeição". Fora do contador não há benchmark por tela contra app de referência: só uma comparação de traços com Mythic Tools que originou a paleta e uma menção a Archidekt/ManaBox/EDHREC como pesquisa. Há plano registrado para elevar o visual (Épico D com 13 BT-UX-* centrado em Deck Details/swap, ordem de execução da Visual Execution Base, backlog P1/P2 da reancoragem e um escopo de 46 superfícies no worktree isolado BT-UX-SYS-001), mas tudo está TODO/BLOCKED_BY_P0, fora do horizonte imediato da fila (que é 100% governança/infra), com aceites estruturais, e o único trabalho estético em andamento está parado e não commitado desde 2026-08-26. No esforço recente, só ~7-8% dos 75 commits que tocaram telas fora do contador em 90 dias foram essencialmente estéticos (tokens, iconografia, identidade MTG, branding), cerca de 61% foram correção/hardening/contrato/evidência, e depois de 2026-08-11 nenhum commit estético entrou no branch canônico. Ressalva: em número de commits dos últimos 90 dias o contador não lidera (18 contra 49 de decks), e o trabalho de layout de hoje nele ainda não está commitado, então a diferença de cuidado aparece no critério de aceite, no benchmark e na infraestrutura de prova, não no volume de commits. Tudo foi feito em modo somente leitura.

**Os gates cobram beleza?** No papel, sim; na prática, não no mesmo nível. O contrato docs/MANALOOM_UI_LIVE_EVIDENCE_CONTRACT.md (linhas 18-21) exige, para TODA superfície, PASS_VISUAL_REVIEWED com decisão explícita sobre "hierarquia, identidade MTG, cor/contraste, tipografia, espaçamento/densidade, adaptação, clareza de interação, estados, acessibilidade visual e atratividade", e a política executável app/test/ui/fixtures/ui_live_evidence_policy.json lista 'attractiveness' entre os 10 required_review_criteria. Porém a verificação real (app/tool/ui_runtime_evidence.dart, linhas 729-738) só exige status == 'pass' e uma nota não vazia: é um checkbox auto-atestado por agente ("reviewer": Codex), sem régua, sem referência externa e sem olho do usuário. Em docs/qa/ui-live/latest.json um ÚNICO parecer de atratividade cobre 439 capturas de todo o app, e a própria nota admite dívida: "densidade wide, carrosséis e estados administrativos permanecem no backlog de polish"; blocking_findings = [] e todos os follow-ups são de truncamento, canvas subutilizado, anchor/offset e cópia, nenhum é "está feio". No play-vs-ai-web-real/visual-review.json a nota de atratividade é "coesa e temática ... feedback visual suficiente" — linguagem de suficiência, não de beleza. O que é verificado de forma dura nas outras telas é posição/estado/overflow/acessibilidade: docs/LAYOUT_TEST_MAP.md lista overflow tests, presença de keys e goldens, e reconhece nos gaps "Nenhum teste de posição/alinhamento/padding — Layout é validado só por 'não estourou'" e "Nenhum golden test para telas funcionais atuais"; dos 6 goldens originais, 5 são do life counter, que ainda tem 4 arquivos com 30+ asserções de geometria via DOM probe. O capture-manifest dos ux-packs (ex.: ux-pack-02-collection-import-web-mobile) registra apenas checkpoints, sha256, bytes, dimensões e console — nenhum juízo estético. Já no contador a beleza é critério de aceite explícito e julgado a olho: TASK_LIFE_COUNTER_PERFEICAO diz "os numeros parecem centrados, nao apenas calculados", "nenhum overlay parece modal genérico", "a mesa pode ser lida como poster". Observação adicional: hoje nem esse gate está verde — latest.json está no digest 865e6041…, 22 dos 23 manifests que ele referencia foram recapturados em 8bba809c… (hash novo, ainda não registrado) e falta play-vs-ai-web-real.

**Benchmark visual fora do contador** Não existe equivalente. O contador tem benchmark formal: docs/SPRINT_LIFE_COUNTER_BENCHMARK_CLONE_2026-03-25.md define 10 capturas como "benchmark oficial", mandato "copiar o benchmark o mais fielmente possivel e depois customizar", seção "Itens do benchmark a copiar 1:1" e aceite "side-by-side com o benchmark deve mostrar a mesma leitura de mesa"; a TASK_LIFE_COUNTER_PERFEICAO fecha com DoD de 7 itens, incluindo "o resultado visual final puder ser chamado honestamente de clone e nao de interpretacao". Para o resto do app, o mais próximo é docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md, que declara que a direção Obsidian + Brass + Frost Blue nasceu "After comparing the current ManaLoom app against live reference captures from MTG Life Counter: Mythic Tools" — mas a seção "QA comparison standard" limita isso a traços de qualidade ("do not copy layouts literally"; a pergunta correta é "what product-quality trait are they solving better than us?"). Não há capturas de referência arquivadas por tela, nem side-by-side, nem critério de aceite ancorado em app de referência para decks, coleção/fichário, comunidade, trocas, perfil ou auth. O backlog mestre (docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md, seção 11) cita "Archidekt, ManaBox e EDHREC como referências comparativas de reconhecimento de cartas, visualização de deck e progressive disclosure — nunca como prova...", apenas como base de pesquisa, sem virar benchmark operacional. O contrato de evidência e o worksheet docs/qa/MANALOOM_SCREEN_UX_AUDIT_WORKSHEET.md não contêm nenhum campo de comparação com referência (o worksheet cobre fluxo, 12 estados e teste de cinco segundos).

**Plano registrado para as outras telas** Existe, mas é estreito, estacionado e com aceite estrutural, não estético. (a) Backlog canônico: "Épico D — UX image-led e redução de densidade textual" no backlog mestre, com 13 tasks BT-UX-* no docs/generated/TASK_REGISTRY.json, todas TODO ou BLOCKED_BY_P0, focadas em Deck Details e troca do Optimize (BT-UX-DECK-002 "Hero do Deck Details com arte grande do comandante", BT-UX-SWAP-001 "Troca visual pareada SAI → ENTRA"). A tese é boa ("Deck Details deixa de parecer um painel administrativo e passa a funcionar como uma bancada viva do comandante"), mas os aceites são do tipo "Aspect ratio 63:88, contain", "Um status, um bloqueio principal e um CTA", "zero overflow a 320 CSS px e 200% texto", "Contraste WCAG, 48 dp". Nenhuma dessas tasks está no horizonte imediato de docs/execution/CURRENT_QUEUE.md (11 IDs, todos de governança/infra: BT-SCP-001, BT-OFFER-001, BT-GATE-001/002, BT-DB-*, BT-CAP-001, BT-DR-001, BT-KPI-001, BT-OBS-001) e a fila diz que "BT-UX-PROOF-001 fica na onda final". Coleção/fichário, comunidade, trocas, perfil e auth não têm task visual dedicada no registry (fora do Épico D só aparecem PG-P1-02 pós-jogo image-led e BT-ACT-002). (b) Plano antigo: a Visual Execution Base tem "Recommended execution order" de 8 passos (auth → home → deck entry → deck details → optimize → collection/binder → profile → secundárias) e a seção "What must be improved" (inclui "Make collection and binder feel more premium"), sem IDs nem datas. (c) Backlog de polish da reancoragem (docs/qa/MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md): 6 itens P1/P2 de truncamento de aba, densidade wide, carrosséis, wrap de nomes, fixture e Legal. (d) Trabalho isolado não canônico: worktree ~/.codex/worktrees/manaloom-ui-home-wave-01 com a ficha BT-UX-SYS-001 ("escopo visual de 46 superfícies", onda 01 = fundação Obsidian/Frost/Brass + shell + Home; "Commit, push, merge ... proibidos nesta fase"; "Task packet manual, isolado e ainda não reconciliado com backlog/registry"), com mudanças não commitadas e parado desde 2026-08-26; e o worktree manaloom-bt-ux-fix-001 (fixtures patológicas), parado desde 2026-08-28. Não existe nenhum plano registrado com o padrão que hoje se cobra no contador (objetos visuais, azulejos, miniaturas, superfície viva ao fundo, julgamento a olho pelo usuário).

**Esforço recente** Contagem pedida (90 dias, git log --oneline | wc -l): app/lib/features/home/life_counter = 9, lotus = 15 (união = 18). Outras features: decks 49, battle 28, home 27 (inclui o contador), auth 16, commercial 16, community 12, binder 11, profile 11, cards 10, collection 8, trades 7. Ou seja, em commits o contador NÃO lidera nos últimos 90 dias; os últimos commits específicos dele são de 2026-07-17 (7 "fix(life-counter)" no mesmo dia, vários de apresentação: "harden tabletop presentation", "face cards toward table seats", "replace Lotus commander dagger", "preserve web state and horizontal readability"). O cuidado de layout de hoje (2026-09-21) no contador não está commitado neste checkout (git status não mostra nada em app/lib), então o git subestima esse esforço. A assimetria estrutural é o dado mais forte: 157 de 384 arquivos de teste (41%) e 56 de 235 arquivos Dart de app/lib (24%) são de life counter/Lotus, e só ele tem docs de sprint de clone e task de "perfeição". Nas outras telas: 75 commits tocaram app/lib fora do contador em 90 dias; 46 (61%) têm fix/harden/contract/gate/evidence/validation no assunto; 13 (17%) mencionam ui/visual/polish/branding, e destes só 5-6 (~7-8%) são essencialmente estéticos: "Polish launch visual surfaces" (11 arquivos, +195/-108), "chore: tighten launch visual token discipline" (35 arquivos), "chore: refresh launch branding assets", "Polish ManaLoom domain iconography" (16 arquivos) e "feat(ui): strengthen MTG identity and recertify live evidence" (14 arquivos, +688/-441). O maior commit de UI, "feat: complete ManaLoom UX audit packs" (72 arquivos, +17958; profile_screen 2339 linhas, binder_screen 794, home_screen 744), é majoritariamente cobertura de estados, responsividade, fixtures e evidência. O polish P1 de 2026-08-06 foi correção de truncamento ("Visão Ge") e recomposição de estados vazios em desktop/wide. Depois do rebrand de 2026-08-11, apenas 3 commits tocaram app/lib fora do contador (baseline all-off, enforce free beta surfaces, Jogar contra IA) — nenhum estético; o único trabalho estético posterior está parado e não commitado no worktree ui-home-wave-01.

## Limites desta auditoria

ESCOPO REAL DO APP. O roteador é go_router em /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app/lib/main.dart (linhas ~440-905): 46 GoRoutes + 1 ShellRoute, das quais 5 são só redirects (/market, /marketplace, /quotes, battle-coach x2) e 1 é o contador de vida. Há 43 arquivos *_screen.dart (42 fora do contador; BattleLiveSpectatorScreen não tem rota própria). O inventário oficial do próprio repo (/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app/test/ui/fixtures/ui_surface_inventory.json) declara além das rotas: 7 MaterialPageRoute, 51 diálogos, 24 bottom sheets, 9 menus, 10 conjuntos de abas (parte disso pertence ao contador).

O QUE A AUDITORIA COBRIU BEM. Em nível de ROTA a cobertura é alta: das ~40 rotas reais fora do contador, só UMA não tem imagem nenhuma — o Scanner. Os checkpoints do p0-matrix (54 por perfil) e os 8 ux-packs tocam praticamente todas as rotas.

O QUE FICOU DE FORA (o ponto cego é de ESTADO e de ABA, não de rota). (1) Scanner: zero imagem. (2) Duas das quatro abas do detalhe do deck — 'Cartas' e 'Análise' — nunca foram fotografadas; a 'Análise' + painel de diagnóstico somam ~4.900 linhas de UI e são a maior superfície não julgada do produto (o único golden é de fonte-bloco, em goldens/ci, fora das pastas auditadas). (3) As telas sociais de conteúdo só foram vistas VAZIAS ou em ERRO: chat (só 'indisponível'), inbox de mensagens, inbox de trades, notificações, feed 'Seguindo' e Cotações. Ou seja, as notas 4/4,5 desses grupos julgam sobretudo o AppStatePanel (que é bonito e consistente), não a tela com dados. (4) Boa parte dos 51 diálogos/24 sheets não tem imagem — em especial o 'Editar carta do deck', que por código é AlertDialog + TextField + Dropdowns. (5) Recuperar senha tem golden mas não entrou em nenhum grupo da auditoria; redefinir senha só no estado de link inválido; verificar email só deslogado. (6) Nenhuma captura é iOS nem tema claro; listas densas (muitos decks, fichário grande) nunca foram vistas — os fixtures têm 1 deck e 1 carta.

LEITURA POR CÓDIGO (inferência, não imagem). As superfícies não capturadas NÃO são, em geral, formulários crus: Scanner, aba Análise e aba Cartas usam CustomPaint, CardArtwork, glifos ManaLoom, azulejos de métrica e gráficos — mesmo vocabulário das telas que tiraram 4-4,5. Os pontos onde o código indica queda real de cuidado são: o estado de permissão e o loading do Scanner (fora do sistema visual, cores cruas preto/branco, moldura sem motion); o chat/inbox populados (ListTile + CircleAvatar, bolhas sem agrupamento nem embed de carta); a aba Cotações (ranking tabular sem toque, vazio que não usa o AppStatePanel, US$ vs R$); e o diálogo de editar carta do deck (formulário em AlertDialog). Estimativa para esse conjunto não capturado: 3,5 em média, contra 4-4,5 do que foi capturado.

RESPOSTA À PERGUNTA DO USUÁRIO, do ângulo da cobertura: o cuidado visual das demais telas é bom e sistemático (tokens, AppStatePanel, arte de carta), mas NÃO está no mesmo nível de verificação do contador: o contador tem dezenas de smoke tests visuais por overlay, enquanto fora dele há superfícies grandes (aba Análise, aba Cartas, Scanner, chat com mensagens, Cotações com dados) que nunca foram olhadas em imagem por ninguém — nem por teste, nem por esta auditoria. As notas revisadas de 'social-trade', 'home/notificações' e 'binder-scanner' devem ser lidas com essa ressalva. Próximo passo recomendado (somente leitura aqui, nada foi alterado): adicionar ao harness app_existing_user_visual_audit_test.dart checkpoints populados para deck_detail_cards, deck_detail_analysis, chat_populated, messages_inbox_populated, trades_inbox_populated, notifications_populated, community_quotes_populated, deck_card_edit_dialog e um scanner com câmera simulada (permission_denied, detecting, preview, not_found).

**Telas e estados sem captura**

- Scanner de carta (rota /decks/:id/search/scan — CardScannerScreen + ScannedCardPreview + CardNotFoundWidget + erro de permissão de câmera): ZERO capturas e zero goldens em qualquer perfil; só existe teste de widget sem imagem
- Detalhe do deck — aba 'Cartas' (lista das 100 cartas agrupadas por tipo, swipe Editar/Excluir): nenhuma captura; os packs só fotografam 'Visão Geral' e 'Oficina'
- Detalhe do deck — aba 'Análise' (DeckAnalysisTab + DeckDiagnosticPanel, ~4.900 linhas: tira de métricas, gráfico de curva, pizza de cores, funções do deck, Plano Commander, evidências de Battle): sem captura real; o único golden (app/test/ui/goldens/ci/manaloom_deck_analysis_summary.png) é de fonte-bloco (Ahem), serve para layout e não para julgamento visual
- Chat / conversa com mensagens (rota /messages/:conversationId): só existe o estado de erro 'chat_unavailable'; bolhas, composer ativo, menu de denúncia/bloqueio nunca foram fotografados
- Comunidade > Cotações POPULADA (features/market — sub-abas Valorizando/Desvalorizando com _MarketMoverCard): só o estado 'Dados insuficientes' foi capturado
- Notificações com lista (tile lido/não lido, avatar por tipo, 'marcar todas'): só o vazio foi capturado — o próprio auditor marcou como 'avaliado pelo código'
- Caixa de mensagens populada (lista de conversas com avatar, prévia, badge de não lidas): só o vazio
- Trades — inbox populada (abas Recebidas / Enviadas / Finalizadas com cartões de proposta): só o vazio
- Redefinir senha — formulário válido (rota /reset-password): só o estado 'link inválido' foi capturado; Recuperar senha (/forgot-password) tem golden 'forgot_password_empty' mas NÃO aparece em nenhum grupo da auditoria, nem o estado de sucesso 'email enviado'
- Verificar email com usuário logado (estado principal, com reenvio): só a variante deslogada
- Fichário — aba 'Quero' populada, 'Resumo da coleção' expandido (12 métricas), filtros/ordenação ativos e lista com muitos itens (a única captura populada tem 1 carta)
- Perfil público — abas Seguidores / Seguindo / Fichário do outro jogador (só o topo + aba Decks foi visto)
- Comunidade > Seguindo com feed populado (só vazio)
- Lista de decks com vários decks (só 1 deck/spotlight e vazio foram vistos — a densidade real da grade nunca foi julgada)
- Diálogo 'Editar carta do deck' (deck_card_edit_dialog.dart — AlertDialog com TextField + 2-4 DropdownButton): sem captura
- Diálogos/folhas do detalhe do deck (deck_details_dialogs.dart): editor de descrição, confirmar remoção de carta, 'Análise: <carta>' (explicação IA), seletor de edição (bottom sheet), detalhe de preços (bottom sheet com ListTile) — sem captura no mobile (só o preview de carta no desktop foi visto)
- Diálogo 'Importar lista para o deck' (deck_import_list_dialog.dart) e menu 'Adicionar cartas' (deck_add_cards_menu.dart)
- Diálogos de feedback do deck (deck_feedback_dialogs.dart) e diálogos de otimização (deck_optimize_dialogs.dart — 6 chamadas de overlay; só parte aparece no pack 03)
- Diálogo de denúncia (social_report_dialog.dart — AlertDialog + Dropdown + TextField) e fluxo de bloquear jogador no chat/perfil
- Gate de uso de IA (commercial/widgets/ai_usage_gate.dart + ai_usage_meter): só golden CI de fonte-bloco
- Painel de growth 'Matches para suas faltantes' (features/growth/widgets/community_trade_growth_panel.dart) — depende de flag + stats do fichário; não confirmado em nenhuma captura
- Estados de carregamento/skeleton de praticamente todas as telas e o NotificationPermissionBoundary (pedido de permissão de push)
- Tema claro / outros temas: todas as capturas são do tema escuro
- iOS: nenhum perfil de captura é iOS (só web 390/1440/1920 e Android)

**Leitura por código (inferência, não imagem)**

- **Scanner de carta (INFERÊNCIA DE CÓDIGO, não de imagem)** (`app/lib/features/scanner/screens/card_scanner_screen.dart (+ widgets/scanner_overlay.dart, widgets/scanned_card_preview.dart)`): Não é formulário: é um Stack de câmera em tela cheia (CameraPreview) com máscara escurecida e moldura de carta desenhada em CustomPaint com cantoneiras, pílula 'Detectando: <nome>' ao vivo, selo dourado de 'Modo Foil', botão-obturador circular de captura manual e, ao reconhecer, um ScannedCardPreview com a arte da carta grande, barra de info (raridade, custo de mana) e lista de edições com miniaturas. Estruturalmente é uma das telas mais 'produto' fora do contador. Pontos fracos prováveis: (1) usa Colors.black/Colors.white cruas em vez dos tokens do tema (fundo preto puro, não o 'abyss' do resto do app) — deve parecer uma tela de outro app; (2) a moldura é ESTÁTICA — só troca a cor da borda quando processa, sem linha de varredura nem pulso, então o momento 'mágico' do scan não tem motion; (3) loading é CircularProgressIndicator branco genérico em caixa preta ('Analisando imagem...'); (4) o erro de permissão é Icon + Text + ElevatedButton soltos, NÃO usa o AppStatePanel desenhado que todas as outras telas usam — é o estado mais cru do app; (5) 'Carta não encontrada' cai num TextField + OutlinedButton simples. Nota provável: 3,5 — boa ossatura, acabamento fora do sistema visual. Confiança baixa: depende de câmera real, nunca foi fotografado.
- **Detalhe do deck — aba 'Análise' (INFERÊNCIA DE CÓDIGO; único golden é de fonte-bloco)** (`app/lib/features/decks/widgets/deck_analysis_tab.dart (+ deck_diagnostic_panel.dart)`): Zero cheiro de formulário: nenhum ListTile/Switch/TextField no arquivo da aba. Composição: cabeçalho 'Análise do deck', tira de 4 azulejos de métrica (_SummaryMetricTile: validação, preço total, curva média, contagem) com ícone colorido + ponto de status, pílula de estado, CTA dourado 'Gerar/Atualizar análise', e uma sequência de _SectionCard: 'Leitura de sinergia' (pontos fortes em verde / fracos em laranja), 'Funções do deck' (8 buckets expansíveis — ramp, compra, remoção, wipes, proteção, tutor, recursão, wincon — com miniaturas de carta e badge de quantidade), 'Plano Commander' (fontes e confiança), 'Base de mana' com BarChart da curva e PieChart de cores (fl_chart), lançador de Battle Lab e 'Evidências de confronto'. Usa 9 vezes os glifos/motivos ManaLoom e CardArtwork. É provavelmente a tela mais rica do app em dados visuais e está no mesmo nível de cuidado da Visão Geral (4,5). Risco visual: MUITOS cartões empilhados (8 Card + 10 no painel de diagnóstico) com título+subtítulo explicativo em cada um — tendência a 'parede de cartões' longa e textual no mobile; os gráficos são fl_chart padrão, não numerais grandes sobre a mesa. O golden CI confirma só a grade 2x2 de azulejos + CTA + cartões empilhados. É a maior superfície não julgada do produto.
- **Detalhe do deck — aba 'Cartas' (INFERÊNCIA DE CÓDIGO)** (`app/lib/features/decks/screens/deck_details_screen.dart (linhas ~997-1400, _buildCardSectionSlivers / _buildDeckCardTile)`): Lista em slivers agrupada por seção (Comandante, tipos), cada carta num Card com borda fina, miniatura CardArtwork 44x62, nome em titleSmall bold, pílula '3x' na cor primária e uma fileira de meta-pílulas (edição, acabamento, raridade, 'Reserved', condição, 'Inválida' em vermelho). Comandante ganha selo dourado com glifo próprio. Swipe (Dismissible) revela 'Editar' / 'Excluir'. Não é ListTile cru — é o mesmo vocabulário de pílulas do Fichário que já foi capturado (nota 4). Leitura provável: correta e consistente, porém é uma lista vertical de ~100 linhas densas de pílulas; não há modo grade/galeria de artes, então a tela onde o jogador mais 'olha o deck' é a menos visual do detalhe. O toque em editar abre o deck_card_edit_dialog, que é o ponto mais fraco (ver abaixo). Nota provável: 4 para a lista, 3 para o diálogo de edição.
- **Chat / conversa populada (INFERÊNCIA DE CÓDIGO; só o estado de erro tem captura)** (`app/lib/features/messages/screens/chat_screen.dart (+ message_inbox_screen.dart)`): Chat convencional bem tokenizado: coluna de leitura com largura máxima, ListView reverso de _MessageBubble (minhas em latão translúcido com borda brass, do outro em surfaceSlate, canto 'rabicho' assimétrico, hora em fontXs), composer arredondado com botão enviar em latão e spinner ao enviar; estados vazio/erro/carregando usam o AppStatePanel desenhado (o que a captura de erro confirma). Faltas prováveis frente ao nível do contador: sem separadores de dia, sem agrupamento de mensagens consecutivas, sem avatar na bolha, sem qualquer embed de carta/proposta de troca (o chat existe para combinar trocas, mas é só texto), e cada mensagem recebida carrega um IconButton more_vert ao lado — ruído visual repetido em toda a coluna. O menu do AppBar usa ListTile dense (denunciar/bloquear) e a confirmação é AlertDialog padrão. A inbox populada é ListTile + CircleAvatar + badge de não lidas — a primitiva mais 'material default' entre as telas sociais. Nota provável: 3,5 (funcional e limpo, sem identidade própria).
- **Comunidade > Cotações populada — 'market' (INFERÊNCIA DE CÓDIGO; só o vazio tem captura)** (`app/lib/features/community/screens/community_screen.dart (linhas ~1399-2000, _CotacoesTab / _MarketMoverCard) + app/lib/features/market/`): Não existe tela /market própria: as rotas /market e /quotes só redirecionam para esta aba. Populada, mostra cabeçalho de datas ('hoje vs ontem'), chip 'N cartas', botão atualizar, sub-abas 'Valorizando / Desvalorizando' e uma lista (grade de 2 colunas em telas largas) de _MarketMoverCard: caixa de ranking '#1', miniatura 36x50, nome, set, preço em dólar e variação % / US$ em verde ou vermelho com seta; top 3 ganha borda levemente mais forte. Sem cheiro de formulário, mas é um ranking tabular: miniatura pequena, sem sparkline/histórico, sem destaque real para o pódio, e pelo que li o cartão não tem onTap (não leva ao detalhe da carta) — beco sem saída visual. Preço em US$ enquanto o Fichário mostra R$ (inconsistência visível). O estado vazio capturado (ampulheta + texto solto) NÃO usa o AppStatePanel com motivo de cartas que todo o resto do app usa — é a tela que mais destoa do sistema visual entre as capturadas, e a versão populada provavelmente fica em 3,5.
- **Diálogos 'Editar carta do deck' e 'Denunciar' (INFERÊNCIA DE CÓDIGO) — os dois pontos com cheiro de formulário mais forte** (`app/lib/features/decks/widgets/deck_card_edit_dialog.dart e app/lib/features/social/widgets/social_report_dialog.dart`): deck_card_edit_dialog: AlertDialog com TextField 'Quantidade' + DropdownButton 'Edição (set)' + DropdownButton 'Condição' + Cancelar/Salvar — é exatamente o padrão formulário/modal que a diretriz do projeto manda evitar; contrasta com a folha 'Editar carta' do Fichário (binder_item_editor, capturada) que já tem arte + seletor de edições desenhado. Aqui a mesma tarefa (trocar edição de uma carta) é resolvida com dropdown de texto, sem miniatura da impressão. social_report_dialog: AlertDialog + Dropdown de motivo + TextField — aceitável por ser fluxo raro de segurança. Os demais diálogos do deck (descrição, remover carta, explicação IA) usam um DialogTitleBlock próprio com título+subtítulo, então estão um degrau acima do AlertDialog cru; a folha de preços usa ListTile simples ('3× Nome' / subtítulo). Nota provável: 3 para o editor de carta do deck, 3,5 para os demais.

---

# Detalhe por área

## Home, onboarding, notificações, splash

**Auditor 4 → revisor 4.5** · correto, genérico · auditor foi *justo*

Não, esta área não está no nível do contador. Dou nota 4/10: nível "correto-genérico" no conjunto, com três superfícies que são formulário.

Abri 12 capturas mobile além da referência do hub e li o código da área. Nenhuma tela usa a gramática do contador (azulejos-objeto, numerais serifados enormes, estado dentro do objeto, material com gradiente, tudo visível de uma vez).

A distância por tela:
- **Home:** é a melhor. Tem herói único, botão dourado, profundidade e arte real de comandante em produção (CardArtwork + fallback Scryfall). Mas a arte do herói é um wireframe genérico de marca. O "Acesso rápido" são duas linhas de ícone + rótulo num carrossel que esconde ações. A arte do deck é um selo de 72x102 e a contagem "100/100" está em 12px. Deck sem comandante vira um retângulo cinza (isso acontece em produção, não é artefato de fixture). Quase 40% da tela fica vazia.
- **Splash:** correto. O wordmark serifado é bom. A arte de fundo é praticamente invisível e o loader é o spinner padrão.
- **Notificações:** o estado vazio é o mais bem desenhado da área (órbitas, halo dourado, título serifado), mas aparece com o eyebrow errado "PRÓXIMO PASSO". A lista real é uma linha de inbox genérica com ícones Material.
- **Onboarding "Seu primeiro passo":** é a pior tela, e é a primeira que o usuário novo vê. É um wizard numerado com lista de linhas com chevron, chips, dropdown, radio, botão largo e cerca de 14 blocos de texto. Não tem um único elemento de Magic.
- **Folha "Qual partida você vai abrir?":** é um modal com linhas de lista e botão largo, exatamente na porta do contador. É onde a quebra de qualidade fica mais evidente.
- **Pós-jogo:** tem três campos de texto empilhados (dois deles são escolhas fechadas tratadas como texto livre), chips e botões desabilitados no topo. Só o herói de origem, com carta inteira e gradiente dourado, tem o material certo.

O contador foi desenhado peça a peça, como objeto. Estas telas foram montadas com componentes Material corretos sobre o tema escuro. Os tokens e a fonte display existem no tema (Fraunces em headline/titleLarge), mas quase não são usados com intenção. A paleta em latão, os glifos próprios, o CardArtwork e o estado vazio de notificações dão base para subir a Home e as Notificações com ganhos baratos. Onboarding, a entrada do "Jogar agora" e o Pós-jogo precisam de redesenho de verdade.

- **Melhor tela:** Home (estado com deck e arte de comandante, home_top.png). É a única tela da área com um herói claro, material com profundidade e arte de carta real em produção. Ainda assim fica um degrau inteiro abaixo do contador.
- **Pior tela:** Onboarding 'Seu primeiro passo' (onboarding_intent_00_first_run.png / _01_build_path.png). A primeira tela do usuário novo é um formulário numerado com lista de linhas, chips, dropdown, radio e botão largo. A tela Pós-jogo é tão formulário quanto ela. A folha modal 'Qual partida você vai abrir?' é a quebra mais abrupta, por ser a porta do contador.

### Notas por tela

| Tela | Obj | Hier | Tipo | Mat | MTG | Resp | Est | 1ªimp | Média | Veredito |
|---|---|---|---|---|---|---|---|---|---|---|
| Home (Início) — estados: com deck, vazio pós-skip, onboarding concluído, quick actions rolado | 3 | 4 | 3 | 3 | 2 | 3 | 3 | 3 | 3.0 | correto, genérico |
| Onboarding 'Seu primeiro passo' (primeira execução, caminho montar deck, plano retomado, fluxo com 5 objetivos) | 1 | 2 | 2 | 2 | 1 | 2 | 3 | 2 | 1.9 | formulário |
| Splash | 3 | 4 | 4 | 2 | 2 | 5 | 2 | 3 | 3.1 | correto, genérico |
| Notificações (vazio capturado; lista avaliada pelo código) | 2 | 3 | 3 | 3 | 2 | 4 | 4 | 3 | 3.0 | correto, genérico |
| Folha 'Qual partida você vai abrir?' (entrada do Jogar agora, porta do contador) | 2 | 2 | 3 | 2 | 2 | 3 | 2 | 2 | 2.2 | formulário |
| Pós-jogo (retention/post_game_notes_screen) | 2 | 2 | 2 | 3 | 3 | 2 | 1 | 2 | 2.1 | formulário |

#### Home (Início) — estados: com deck, vazio pós-skip, onboarding concluído, quick actions rolado

Captura: `app/test/ui/goldens/runtime/web_mobile/home_top.png (+ home_quick_actions_scrolled.png, ux-pack-06/onboarding_intent_03_skipped_home.png, onboarding_intent_04_completed_home.png)`

**Problemas**

- A arte do herói é um wireframe genérico de marca (assets/branding/home_hero.png: cartões cinza com o logo), usada via Image.asset fixo em home_screen.dart:1257. Mesmo quando o herói diz 'Continue Izzet Phoenix…', a arte do comandante/deck não aparece. É a maior superfície da tela e não tem nada de Magic.
- 'Acesso rápido' não são azulejos: cada _QuickActionCard (home_screen.dart:1593-1647) é uma linha com ícone de 21px + rótulo de 12px em caixa chapada (surfaceSlate + contorno hairline), altura 72 (linha 1503). Não tem numeral, estado ou miniatura. Compare com MESA/PARTIDAS/COROA do contador.
- O Acesso rápido é um carrossel horizontal com 2 visíveis (home_screen.dart:1494-1519). 'Coleção' e 'Trocas' ficam escondidos fora da tela, o oposto de 'tudo visível de uma vez'. As capturas home_top e home_quick_actions_scrolled são praticamente idênticas, o que mostra como o scroll passa despercebido.
- O cartão de deck recente trata a arte como selo: 72x102 (home_screen.dart:1715-1717) ao lado de 5 linhas de texto de 11-12px. '100/100' está em fontXs 12px (1777-1783), quando pediria um numeral serifado expressivo. Os pips de mana têm 12px (1907).
- Deck sem comandante (Modern etc.) cai em _DeckFallback (home_screen.dart:1852-1885): gradiente quase cinza com glifo de deck a 26% de opacidade. Na captura 04 aparece como um retângulo cinza com ícone de documento. Isso não é artefato de fixture: em produção, um deck sem commanderImageUrl e sem commanderName (1834-1848) mostra exatamente isso.
- Com 1 deck, cerca de 35-40% da tela abaixo do trilho fica vazia. Não há partida pausada, último pós-jogo, estatísticas em numerais nem nada vivo. A tela parece inacabada.
- A serifada Fraunces aparece só no título do herói e nos cabeçalhos de seção (18px). Não há contraste de escala nem numerais grandes em lugar nenhum.
- O estado vazio de decks (home_screen.dart:1915-1991) é caixa com contorno + ícone 28px + botão largo 'Criar novo deck' (1979-1986): correto e genérico. O erro (1993-2040) é caixa vermelha com Icons.cloud_off e OutlinedButton.
- A barra inferior é a NavigationBar padrão do Material (main_scaffold.dart:130-142). Os glifos próprios ajudam, mas o resto é de fábrica.

**Acertos**

- Há um herói único, com botão dourado e uma ação primária clara, e ele muda de conteúdo conforme o estado (Olá / Seu primeiro deck / Continue X).
- O herói tem profundidade real: sombra de 28px, moldura em latão pintada por cima, gradiente de leitura sobre a arte (home_screen.dart:1226-1295).
- Usa glifos próprios (ManaLoomGlyph) em vez de ícones Material nas ações e na navegação.
- Em produção o cartão de deck usa arte real: CardArtwork com commanderImageUrl e fallback Scryfall por nome (home_screen.dart:1834-1846). A arte do golden é fixture (visual_fixture_arcane_ring.webp).
- A moldura do cartão vira latão quando o deck está completo (1686), então a cor tem significado.

#### Onboarding 'Seu primeiro passo' (primeira execução, caminho montar deck, plano retomado, fluxo com 5 objetivos)

Captura: `docs/qa/ui-live/current/ux-pack-06-onboarding-intent-web-mobile/onboarding_intent_00_first_run.png (+ _01_build_path.png, _02_resumed_plan.png, goldens/runtime/web_mobile/onboarding_core_flow.png)`

**Problemas**

- É um formulário numerado em três caixas ('1 · Escolha seu objetivo', '2 · Conte sobre seu momento', '3 · Comece manualmente'), exatamente a superfície estilo configurações que o dono rejeita, e é a PRIMEIRA tela que o usuário novo vê.
- Os objetivos são uma lista de configurações: _GoalRail/_GoalRow (onboarding_core_flow_screen.dart:760-935) com Divider de 1px entre linhas (818), ícone Material de 21px em caixinha de 42px (874-896), título + descrição e chevron à direita (921-927). São cinco linhas de texto empilhadas, sem nenhuma ilustração do que é 'montar', 'importar' ou 'jogar'.
- A experiência é uma sopa de chips: Wrap de ChoiceChip com checkmark (onboarding_core_flow_screen.dart:1000-1016). Em 390px quebra em 2+1 ('Começando agora', 'Voltando ao Magic' / 'Jogo com frequência').
- O formato principal é um DropdownButtonFormField com labelText e helperText (onboarding_core_flow_screen.dart:1018-1041), campo de formulário puro. Commander/Modern/Standard pediam azulejos com numeral serifado (100, 60) e símbolo.
- O modo de construção é uma linha com radio button: _BuildModeTile usa Icons.radio_button_checked (onboarding_core_flow_screen.dart:1344-1350) em caixa com contorno de 1px (1309-1314). Abaixo vem um botão largo FilledButton de largura total (1168-1199) e um link de texto dourado.
- Parede de texto: cada caixa tem título + subtítulo explicativo, cada opção tem descrição, e ainda há helper do dropdown, parágrafo sob o seletor (1157-1165), aviso 'Escolha também seu momento…' (1201-1210) e 'Pular por enquanto — seu objetivo continua salvo'. São cerca de 14 blocos de texto em uma rolagem.
- O material é chapado: as duas caixas principais são surfaceSlate a 72% + Border.all(outlineMuted) (onboarding_core_flow_screen.dart:778-784 e 974-981), sem gradiente, sem profundidade e sem cor com significado além do latão do selecionado.
- Não há Magic na tela: nenhuma arte de carta, nenhum símbolo de mana, só ícones Material genéricos (estilo, clipboard, arquivo, gamepad, tune). O herói reaproveita o mesmo wireframe home_hero.png a 48% de opacidade (598-613), e o que resta visível é um contorno cinza no canto.
- O progresso '1 · Objetivo / 2 · Contexto / 3 · Ação' é texto de 12px sobre barra de 3px (onboarding_core_flow_screen.dart:723-757), quase invisível, e reforça a cara de wizard de formulário.
- A ação primária fica abaixo da dobra na primeira execução, e o título da AppBar 'Seu primeiro passo' é sans simples.

**Acertos**

- A manchete do herói em Fraunces w900 ('O que você quer fazer primeiro?') com eyebrow em latão tem boa voz (onboarding_core_flow_screen.dart:647-672).
- O estado selecionado é desenhado: o ícone preenche em latão, a linha ganha tinta dourada e check (860-927), e os segmentos de progresso acendem.
- Tudo cabe numa única rota, sem modais aninhados. A estrutura de decisão (objetivo → contexto → ação) está certa. Falta a forma visual.

#### Splash

Captura: `app/test/ui/goldens/runtime/web_mobile/splash_boot.png`

**Problemas**

- A 'arte de abertura' (assets/branding/splash_art.png, splash_screen.dart:86-90) são elipses cinza-azuladas quase da cor do fundo, com meia dúzia de pontinhos. Na captura parece uma mancha/artefato de renderização, não arte. Não há textura de mesa, carta nem brilho.
- O logo fica numa caixa de 116px com contorno hairline a 24% (splash_screen.dart:123-140), sem brilho, sem sombra e sem halo dourado.
- O carregamento é um CircularProgressIndicator padrão de 32px (splash_screen.dart:182-190), o spinner mais genérico possível, no rodapé.
- Nada indica que é um app de Magic: nenhum símbolo de mana, carta ou mesa.

**Acertos**

- O wordmark 'BrewTact' em Fraunces w900 a 34px (splash_screen.dart:154-165) é o melhor uso isolado da tipografia display na área.
- A composição centrada tem respiro amplo, e o logo entra com fade + scale.
- A hierarquia é clara: logo → nome → tagline.

#### Notificações (vazio capturado; lista avaliada pelo código)

Captura: `app/test/ui/goldens/runtime/web_mobile/notifications.png`

**Problemas**

- Erro de copy visível: o eyebrow 'PRÓXIMO PASSO' aparece acima de 'Nenhuma notificação'. Ele vem do padrão AppStateStatus.information em app_state_panel.dart:68, aplicado ao vazio em notification_screen.dart:140-147. Não existe próximo passo algum, e parece template reaproveitado.
- A lista real (_NotificationTile, notification_screen.dart:209-312) é uma linha de caixa de entrada genérica: CircleAvatar de 20px com ícone Material (259-269: person_add, inbox, local_shipping, chat_bubble…), título de 14px, corpo de 12px e hora à direita, em caixa surfaceSlate com contorno (229-239). Não tem arte da carta trocada, avatar do usuário, miniatura do deck nem agrupamento por dia.
- A lista não tem tipografia display. Tudo é TextStyle manual sans (275-305).
- Os estados de carregamento e erro são o AppStatePanel compartilhado (118-137): consistentes, mas sem nada específico de notificações.
- O ponto focal do vazio é um sino Material dentro de um círculo. Funciona, mas é o ícone mais previsível possível.

**Acertos**

- O estado vazio É desenhado: órbitas concêntricas com pontos, contornos de cartas ao fundo, halo dourado no sino, título serifado. Está acima da média da área e é o único estado vazio com intenção ilustrativa.
- A notificação não lida tem linguagem própria: barra de latão de 4px + tinta dourada + borda dourada (notification_screen.dart:229-258), então a cor tem significado.
- Bom respiro e nenhuma parede de texto.

#### Folha 'Qual partida você vai abrir?' (entrada do Jogar agora, porta do contador)

Captura: `docs/qa/ui-live/current/ux-pack-04-battle-learning-web-mobile/battle_learning_00_play_entry.png`

**Problemas**

- É um modal bottom sheet (showModalBottomSheet em home_screen.dart:132-148) com alça de arrastar, o padrão que o dono rejeita, e fica exatamente na porta de entrada do contador de vida. O usuário passa de uma folha cinza de lista para a mesa viva de azulejos, e a quebra de qualidade é abrupta.
- Os decks são linhas de lista: _PlayEntryDeckTile (home_screen.dart:1050-1130) tem miniatura de 44x62 (1071-1073), nome, 'Commander · revisão confirmada antes de abrir' em texto miúdo e chevron dourado. A arte do comandante fica do tamanho de um selo.
- A 'Nova partida rápida · sem deck' é um OutlinedButton de largura total (home_screen.dart:1023-1031), um botão largo contornado. Deveria ser um azulejo com raio e numerais '4 jogadores · 40'.
- A sessão pausada (898-970) é uma caixa tingida com 3 linhas de texto + FilledButton 'Retomar' + OutlinedButton 'Encerrar…' num Wrap, sem numeral de turno, vidas ou miniatura da mesa. O contador já tem tudo isso desenhado (tile MESA com miniatura 2x2 e '4 · 40').
- Tem jargão e parede de texto: 'Vincule uma revisão para transformar a mesa em aprendizado, ou declare um modo rápido sem deck' (886-890), 'Revisão d7d1c679 preservada' (937).
- O estado sem decks é um parágrafo em caixa cinza (home_screen.dart:984-999) seguido de TextButton.

**Acertos**

- O título é serifado, com o glifo próprio do contador em latão.
- Em produção a miniatura usa a arte real via CardArtwork (home_screen.dart:1090-1097).

#### Pós-jogo (retention/post_game_notes_screen)

Captura: `app/test/ui/goldens/runtime/web_mobile/post_game_empty.png`

**Problemas**

- O bloco 'Registrar partida' é literalmente um formulário: três TextField empilhados ('Resultado', 'Nível da mesa', 'Notas') em post_game_notes_screen.dart:1272-1299. 'Resultado' e 'Nível da mesa' são texto livre, embora o próprio hintText liste os valores fechados ('Casual, melhorada, otimizada ou cEDH', linha 1286). Isso pedia azulejos.
- Os problemas observados são uma sopa de FilterChip (post_game_notes_screen.dart:1321-1333), e o fechamento é um ElevatedButton largo 'Salvar pós-jogo' com Icons.save (1339-1349).
- A primeira coisa na tela é um painel 'Evolução do deck · 0 jogos' com dois parágrafos de texto e dois botões DESABILITADOS 'Otimizar' / 'Reconstruir' (1130-1139). Abrir a tela com controles mortos e jargão ('handoff autenticado ao Optimize') dá uma péssima primeira impressão.
- O histórico vazio (_EmptyHistoryPanel, post_game_notes_screen.dart:1687-1704) é só uma frase em caixa cinza com contorno, o estado vazio menos desenhado da área.
- São quatro caixas empilhadas com contorno de 1px (1254-1261 e irmãs), e o ponto focal compete entre o painel de evolução, o herói da fonte e o formulário.
- A tipografia display aparece só no nome do deck. Não há numerais expressivos: '0 jogos' em 14px, quando poderia ser o numeral herói.

**Acertos**

- O herói de origem (_PostGameSourceHero, post_game_notes_screen.dart:606-757) tem gradiente dourado, carta inteira via CardArtwork fullCard (697-699), eyebrow em latão e nome serifado. É o único trecho com material no nível certo.
- O seletor de cartas observadas usa arte de carta (CardArtworkVariant.gallery, linha 1630), com toque cíclico Preservar/Revisar, uma boa ideia de objeto visual.

### Cheiros de formulário (arquivo:linha)

- `app/lib/features/home/onboarding_core_flow_screen.dart:817` — _GoalRail: os objetivos são uma lista de configurações com Divider de 1px entre linhas. Cada _GoalRow (836-935) tem ícone Material de 21px, título, descrição e chevron.
- `app/lib/features/home/onboarding_core_flow_screen.dart:1006` — Wrap de ChoiceChip com checkmark para a experiência. É uma sopa de chips que quebra em 2+1 no mobile.
- `app/lib/features/home/onboarding_core_flow_screen.dart:1018` — DropdownButtonFormField 'Formato principal' com labelText e helperText. É campo de formulário puro para uma escolha que devia ser azulejo com numeral.
- `app/lib/features/home/onboarding_core_flow_screen.dart:1344` — _BuildModeTile é uma linha com Icons.radio_button_checked/off dentro de caixa com contorno de 1px (1309-1314).
- `app/lib/features/home/onboarding_core_flow_screen.dart:1172` — FilledButton.icon de largura total como fechamento do formulário, seguido de helper text (1201-1210) e link 'Pular por enquanto'.
- `app/lib/features/home/onboarding_core_flow_screen.dart:778` — As caixas principais são chapadas (surfaceSlate 72% + Border.all outlineMuted), repetidas em 974-981, com títulos numerados '1 ·', '2 ·', '3 ·' de wizard.
- `app/lib/features/home/onboarding_core_flow_screen.dart:746` — O progresso é texto de 12px sobre barra de 3px, um indicador de wizard quase invisível.
- `app/lib/features/home/home_screen.dart:132` — showModalBottomSheet como entrada do 'Jogar agora': um modal na porta do contador de vida.
- `app/lib/features/home/home_screen.dart:1025` — OutlinedButton.icon de largura total 'Nova partida rápida · sem deck', um botão largo contornado.
- `app/lib/features/home/home_screen.dart:1071` — _PlayEntryDeckTile é uma linha de lista com miniatura de 44x62, texto e chevron. A arte do comandante fica do tamanho de um selo.
- `app/lib/features/home/home_screen.dart:948` — A sessão pausada aparece como caixa de texto + FilledButton/OutlinedButton num Wrap, sem numeral de turno ou vida e sem miniatura da mesa.
- `app/lib/features/home/home_screen.dart:1613` — _QuickActionCard é uma linha com ícone de 21px + rótulo de 12px em caixa chapada com contorno hairline, sem estado nem numeral dentro do objeto.
- `app/lib/features/home/home_screen.dart:1504` — O Acesso rápido é uma ListView horizontal com 2 itens visíveis. As ações Coleção e Trocas ficam escondidas fora da tela.
- `app/lib/features/home/home_screen.dart:1257` — O herói usa Image.asset fixo de wireframe de marca e nunca mostra a arte do deck/comandante que ele mesmo anuncia.
- `app/lib/features/home/home_screen.dart:1778` — A contagem '100/100' está em fontXs 12px, o dado mais importante do cartão sem numeral expressivo. A arte fica em 72x102 (1715-1717).
- `app/lib/features/home/home_screen.dart:1852` — _DeckFallback é um retângulo quase cinza com glifo a 26%. É o que decks sem comandante (Modern/Standard) mostram em produção.
- `app/lib/features/home/home_screen.dart:1981` — O estado vazio de decks fecha com FilledButton de largura total dentro de caixa com contorno. É genérico.
- `app/lib/features/notifications/screens/notification_screen.dart:259` — _NotificationTile usa CircleAvatar com ícone Material + título/corpo/hora em caixa com contorno. É uma linha de inbox genérica, sem arte de carta, deck ou usuário.
- `app/lib/core/widgets/app_state_panel.dart:68` — O eyebrow padrão 'PRÓXIMO PASSO' vaza para o vazio de notificações (notification_screen.dart:140), uma copy incoerente com 'Nenhuma notificação'.
- `app/lib/features/retention/screens/post_game_notes_screen.dart:1272` — Três TextField empilhados (Resultado 1272, Nível da mesa 1281, Notas 1290). Os dois primeiros são escolhas fechadas tratadas como texto livre.
- `app/lib/features/retention/screens/post_game_notes_screen.dart:1326` — Sopa de FilterChip para 'Problemas observados'.
- `app/lib/features/retention/screens/post_game_notes_screen.dart:1339` — ElevatedButton.icon largo 'Salvar pós-jogo' com Icons.save.
- `app/lib/features/retention/screens/post_game_notes_screen.dart:1130` — Os botões 'Otimizar' / 'Reconstruir' aparecem desabilitados no topo da tela, junto com dois parágrafos de jargão.
- `app/lib/features/retention/screens/post_game_notes_screen.dart:1687` — _EmptyHistoryPanel é um estado vazio que é só uma frase numa caixa cinza com contorno.
- `app/lib/features/auth/screens/splash_screen.dart:185` — CircularProgressIndicator padrão como único elemento de carregamento. A arte de fundo (linha 86) é praticamente invisível.
- `app/lib/core/widgets/main_scaffold.dart:130` — NavigationBar de fábrica do Material, com apenas os glifos customizados.

### Ganhos rápidos

- Herói da Home: quando o conteúdo for 'Continue <deck>', usar a arte do comandante (CardArtwork/art crop, já disponível em _DeckArtwork, home_screen.dart:1827-1850) como fundo do herói, no lugar do wireframe home_hero.png (1257).
- Acesso rápido: trocar o carrossel de linhas (home_screen.dart:1494-1519, 1593-1647) por uma grade 2x2 de azulejos, tudo visível. Usar glifo de 40px+ e estado dentro do objeto ('3 decks', 'sessão pausada · turno 5'), com material em gradiente. 'Jogar agora' vira o azulejo dourado herói, igual ao PASSAR A VEZ.
- Cartão de deck recente: tornar a arte protagonista (art crop como fundo do cartão, não um selo de 72x102). Usar numeral serifado grande para a contagem ('100' em Fraunces 28-32) e pips de mana de 18px no lugar de 12px (home_screen.dart:1715, 1778, 1907).
- _DeckFallback (home_screen.dart:1852-1885): trocar o retângulo cinza por um gradiente forte da identidade de cor + símbolos de mana grandes. Decks Modern/Standard não podem parecer placeholder.
- Notificações vazio: eliminar o eyebrow 'PRÓXIMO PASSO' (passar eyebrow próprio ou status adequado em notification_screen.dart:140; origem em app_state_panel.dart:68).
- Onboarding: substituir o DropdownButtonFormField (onboarding_core_flow_screen.dart:1018) por azulejos de formato com numeral serifado (100 / 60) e os ChoiceChips (1006) por 3 azulejos com ícone grande. Cortar os textos auxiliares (1157-1165, 1201-1210, helperText 1024).
- Pós-jogo: transformar 'Resultado' e 'Nível da mesa' (post_game_notes_screen.dart:1272-1288) em azulejos de escolha (Vitória/2º/Derrota; Casual/Melhorada/Otimizada/cEDH), porque os valores já estão no hintText. Esconder os botões desabilitados Otimizar/Reconstruir (1130-1139) enquanto houver 0 jogos.
- Splash: dar contraste real à arte (hoje são elipses da cor do fundo) ou trocar por textura de mesa/cartas com brilho dourado. Substituir o spinner genérico (splash_screen.dart:185) por um loader de marca.
- Preencher a metade vazia da Home com azulejos vivos: última partida (numerais de vida/turno, miniatura da mesa), pós-jogo pendente, contagem de decks/partidas em numerais serifados.

### Redesenhos necessários

- Onboarding inteiro: abandonar o wizard de 3 caixas numeradas e redesenhar como uma superfície única de azulejos na gramática do hub do contador. Seriam 5 azulejos de objetivo com miniatura/ilustração do resultado (pilha de cartas com arte, lista importada, fichário, miniatura da mesa 2x2, deck com seta), azulejos de formato com numeral serifado e azulejos de momento. O selecionado vira o azulejo dourado herói com a ação embutida, sem dropdown, chips, radio ou botão largo.
- Entrada do 'Jogar agora' (home_screen.dart:132-148, 807-1130): substituir o modal bottom sheet por uma superfície de tela cheia com azulejos sobre a mesa escurecida. Seriam azulejos de deck com arte do comandante em protagonismo, azulejo 'Partida rápida' com raio + '4 · 40' e miniatura de mesa, e sessão pausada como azulejo dourado com numeral de turno e vidas. Deve ter continuidade visual direta com o contador.
- Home como painel de azulejos vivos: herói com arte real do deck em foco, grade de ações com estado dentro do objeto, trilho de decks com a arte como superfície e seção 'mesa' (última partida / retomar) com numerais expressivos. Hoje é herói + 2 linhas + 1 cartão + vazio.
- Pós-jogo (post_game_notes_screen.dart:1213-1356 e painéis 759-1147): passar de formulário para objetos. O resultado vira azulejos grandes, o nível da mesa vira azulejos, os problemas viram ícones-azulejo, as cartas observadas ficam como grade de arte (a base já existe em 1559-1658) e a evolução vira numerais (jogos, vitórias). O histórico vazio deve ser desenhado.
- Lista de notificações (notification_screen.dart:209-312): usar azulejos tipados com o objeto real (arte da carta da troca, avatar do usuário, miniatura do deck), agrupamento por dia e tipografia display nos títulos, no lugar da linha CircleAvatar + ícone Material.
- Família de estados vazio/erro/carregando da área: o vazio de notificações prova que dá para desenhar. Levar o mesmo cuidado para o vazio/erro de decks da Home (1915-2040) e o histórico do Pós-jogo (1687), hoje caixas com contorno + botão.

### Contestação do revisor

O auditor foi justo: esta área não está no nível do contador, e minha nota revisada é 4,5/10, nível "correto-genérico", com o onboarding como "formulário".

Abri a referência do hub e 13 capturas: as 10 listadas, as 2 extras que ele usou e messages_inbox para comparar. Formei minha nota antes de reler a dele. As 10 afirmações arquivo:linha que conferi batem todas.

**Onde concordo:**
- **Home:** tem herói com profundidade e botão dourado. O resto são linhas de ícone + rótulo num carrossel que esconde ações, arte do deck em selo de 72x102 e contagem em 12px. Cerca de 40% da tela fica vazia.
- **Onboarding:** é a pior tela e é a primeira que o usuário novo vê. Tem lista com chevron, chips, dropdown, radio e botão largo em três caixas numeradas. Ela não tem nenhuma entrada de texto, então não cabe a defesa de que formulário é a forma certa, como caberia em login ou texto legal.
- **Splash e Notificações:** corretas e genéricas.

**Onde ele foi generoso:**
- **Notificações:** deu 4 em "estados" e chamou o vazio de "desenhado". É o template compartilhado AppStatePanel + ManaLoomThemeMotif, idêntico ao de Mensagens. Por isso o eyebrow errado "PRÓXIMO PASSO" vazou. Minha nota é 3.
- **Home:** deu 4 em hierarquia. Ele não viu que a manchete do herói é truncada com reticências em 2 de 3 estados (coluna de 194px, home_screen.dart:1296-1309). Também não viu o mesmo CTA repetido até 3 vezes na mesma dobra. Minha nota é 3.

**Onde ele foi duro ou impreciso:**
- **Splash:** cobrou símbolos de Magic e "estados". Uma splash de 1-2 segundos é legitimamente logo + wordmark. O defeito real é o material e a arte invisível, que ele apontou.
- **Pós-jogo:** anexou a tela (features/retention), que é de outra área.
- **Folha "Jogar agora":** parte da evidência de jargão vem de um ramo de código (canWriteLearning) que não aparece na captura avaliada. O veredito se sustenta pela régua do dono: é modal na porta do contador.

**O que ele perdeu, além do truncamento e dos CTAs repetidos:**
- O onboarding do free beta mostra um radio de opção única (onboarding_core_flow_screen.dart:1244) e a mesma frase repetida 5 vezes.
- A copy fala em "comandante" com Modern selecionado (linhas 1160 e 1447).
- _DeckFallback fica acinzentado para qualquer deck multicolor em produção (app_theme.dart:446), pior do que ele relatou.
- A arte decorativa a 3-5% de contraste é um problema sistêmico: aparece na splash, no motivo de órbitas e no wireframe do herói.
- No release candidate só existem 2 objetivos de onboarding, não 5. Isso barateia o redesenho para 2 azulejos.

As correções para cima e para baixo se compensam. O 4/10 dele fica meio ponto abaixo da minha conta ponderada (Home 40%, Onboarding 35%, Notificações 15%, Splash 10%, cerca de 5/10). Arredondo para 4,5 porque a pior tela é a porta de entrada do usuário novo.

**Discordâncias**

- **Notificações (vazio)** — auditor: Deu 4 em 'estados' e escreveu que 'o estado vazio É desenhado' e que é 'o único estado vazio com intenção ilustrativa' da área. · revisor: Foi generoso. Aquilo não foi desenhado para notificações. É o template compartilhado AppStatePanel + ManaLoomThemeMotif (app_state_panel.dart:86), igual em todo o app. Abri messages_inbox.png para comparar: mesmas órbitas, mesmos contornos de carta, mesmas duas réguas horizontais, mesmo círculo, só troca o ícone. É por ser template que o eyebrow errado 'PRÓXIMO PASSO' vazou. A ilustração tem contraste tão baixo que em 1 segundo só se lê 'sino num círculo + texto entre duas linhas'. As órbitas ficam deslocadas para o canto superior direito e a régua superior as corta, o que parece desalinhamento. Minha nota para 'estados' é 3 (template correto e consistente), não 4. O veredito 'correto-genérico' se mantém.
- **Home** — auditor: Hierarquia 4: 'há um herói único, com botão dourado e uma ação primária clara'. · revisor: Foi generoso em 1 ponto. O herói existe, mas a manchete serifada dele é cortada com reticências em 2 dos 3 estados capturados: 'Seu primeiro deck começa ...' e 'Continue Izzet Phoenix...'. A causa é a coluna de 194px com maxLines: 2 + ellipsis (home_screen.dart:1296-1309). Além disso, a ação primária não é única. Em home_top, 'Jogar agora' aparece no herói e de novo como primeiro item do Acesso rápido. Em 03_skipped_home há TRÊS botões para a mesma ação na mesma dobra: 'Criar deck' no herói, 'Criar deck' no acesso rápido e 'Criar novo deck' no vazio. Minha nota de hierarquia é 3. O veredito 'correto-genérico' se mantém.
- **Splash** — auditor: identidadeMtg 2, com o problema 'Nada indica que é um app de Magic: nenhum símbolo de mana, carta ou mesa'; estados 2 por causa do spinner. · revisor: Foi um pouco duro. A splash dura 1-2 segundos e é um momento de marca: logo + wordmark serifado + tagline é a forma legítima. Pedir símbolo de mana ali não faz sentido (e símbolos de mana em superfície de marca são delicados pela política de conteúdo de fãs da Wizards). O que pesa contra a splash é o material: caixa do logo com hairline, sem brilho, e arte de fundo invisível. Nisso ele acertou (material 2). Eu não puniria identidade nem 'estados' aqui e daria peso baixo à splash na nota da área. O nível 'correto-genérico' está certo.
- **Pós-jogo** — auditor: Incluiu post_game_notes_screen (features/retention) como tela da área e a usou para puxar a nota para baixo (veredito 'formulário', estados 1). · revisor: A análise da tela está correta (conferi os três TextField e o hint com valores fechados), mas ela não pertence a 'Home, onboarding, notificações, splash'. É do pacote battle-learning/retention e deve ser pontuada lá, para não ser contada duas vezes. Já a folha 'Qual partida você vai abrir?' é legítima nesta área, porque mora em home_screen.dart e abre pelo CTA do herói. Tirar o Pós-jogo da conta sobe um pouco a média. Corrigir a generosidade em Notificações e Home desce. O saldo fica onde ele chegou.
- **Folha 'Qual partida você vai abrir?'** — auditor: Veredito 'formulário', citando jargão 'Vincule uma revisão para transformar a mesa em aprendizado…' e 'Revisão d7d1c679 preservada' como problemas. · revisor: O padrão (modal + linha de lista com miniatura de 44x62 + botão largo contornado) é exatamente o que o dono rejeita, e a posição na porta do contador agrava. Concordo com o veredito pela régua do dono. Pelo olho, é uma folha compacta e limpa, na fronteira entre genérico e formulário, não uma tela feia. Parte da evidência de parede de texto foi tirada do código e não da captura: o build capturado (free beta) mostra a copy simples, e o bloco de sessão pausada com hash não aparece na captura. O problema de copy com hash técnico é real para builds com learning ligado, mas ele não viu isso na tela.
- **Onboarding** — auditor: 'São cinco linhas de texto empilhadas' no trilho de objetivos. · revisor: O veredito 'formulário' está certo e eu o reforço: a tela NÃO TEM NENHUMA entrada de texto. Tudo é escolha entre 2-5 opções fechadas, então não há desculpa de que 'formulário é a forma certa' (diferente de login ou texto legal). O detalhe é que no release candidate real (capturas ux-pack-06, free beta) só aparecem 2 objetivos, 'Montar um deck' e 'Importar uma lista', por causa do gate de capabilities (onboarding_core_flow_screen.dart:380-404). As 5 linhas só existem no golden com tudo liberado. Isso não melhora a tela. Fica uma caixa grande com 2 linhas de lista, e os blocos 2 e 3 (chips, dropdown, radio) dominam. Mas muda o custo do redesenho: são 2 azulejos, não 5.

**Problemas que o auditor perdeu**

- Home: a manchete do herói é truncada com reticências a 390px em 2 de 3 estados ('Seu primeiro deck começa ...', 'Continue Izzet Phoenix...'). O texto fica numa coluna fixa de 194px com maxLines: 2 e TextOverflow.ellipsis (home_screen.dart:1296-1309). É o elemento tipográfico mais importante da tela, e o nome do deck que o herói anuncia é justamente o que é cortado.
- Home: CTA duplicado ou triplicado na mesma dobra. 'Jogar agora' aparece no herói e como primeiro item do Acesso rápido (home_top.png). No estado vazio, 'Criar deck' (herói) + 'Criar deck' (acesso rápido) + 'Criar novo deck' (estado vazio) aparecem juntos (onboarding_intent_03_skipped_home.png). O carrossel só mostra 2 itens e gasta um deles repetindo o herói.
- Onboarding no free beta: radio de opção única. Quando generateAllowed é falso, _BuildModeSelector devolve só o tile 'Criar do zero' (onboarding_core_flow_screen.dart:1244, `if (!generateAllowed) return manual;`). O usuário vê um radio marcado sem alternativa (captura 01). A mesma informação se repete 5 vezes em sequência: título 'Comece manualmente', descrição 'Defina nome, formato e comandante…', subtítulo do tile 'Controle carta por carta', parágrafo 'Você começa com nome, formato e comandante…' e botão 'Criar deck do zero'.
- Onboarding: copy incoerente com o formato escolhido. Com 'Modern' selecionado no dropdown (captura 01), os textos continuam dizendo 'Defina nome, formato e comandante' e 'Você começa com nome, formato e comandante' (onboarding_core_flow_screen.dart:1447 e 1160). Modern não tem comandante, e as strings não olham o formato.
- A autoria do 'vazio desenhado' de notificações está errada. É o template genérico AppStatePanel + ManaLoomThemeMotif (app_state_panel.dart:86), idêntico em Mensagens e nas demais telas. A área não tem NENHUM estado desenhado especificamente para ela.
- A arte decorativa invisível é um problema sistêmico, não só da splash. O splash_art.png, o motivo de órbitas do AppStatePanel e o wireframe home_hero.png a 48% de opacidade no onboarding (onboarding_core_flow_screen.dart:604-607) estão todos a cerca de 3-5% de contraste do fundo. O app paga o custo de ter 'arte' e o olho não registra nada, enquanto o contador usa gradientes saturados (dourado, azul-noite) que se leem em 1 segundo.
- _DeckFallback é pior do que o relatado. AppTheme.identityColor (app_theme.dart:439-447) devolve frost600 (cinza-azulado) para QUALQUER identidade multicolor ('keep it quiet/technical'). Todo deck de 2+ cores sem comandante (a maioria dos decks Modern/Standard/Pioneer) vira placeholder acinzentado em produção. Só decks monocoloridos ganham tinta, e mesmo assim a 34% de alfa.
- Home: o trilho de decks recentes é uma ListView horizontal com altura fixa de 144 (home_screen.dart:1655-1672) e cartão de cerca de 245px. Com 1 deck sobra cerca de 1/3 da largura vazia à direita do cartão, além do vazio vertical que o auditor já apontou. O cartão não se adapta à quantidade.
- Onboarding (golden onboarding_core_flow.png): o herói diz 'PLANO RETOMADO · Continue de onde você parou.' com nenhum objetivo selecionado e progresso todo apagado. Isso vem de _resumedProgress ficar verdadeiro por qualquer campo fora do default (onboarding_core_flow_screen.dart:109-114). No golden é combinação de fixture, porque o default de buildMode é guided. Mas o estado 'retomado sem objetivo' é alcançável em produção: basta tocar num chip de momento e sair. Aí a manchete promete continuar algo que não existe.

**Afirmações de código conferidas**

- ✅ O herói da Home usa Image.asset fixo 'assets/branding/home_hero.png' (home_screen.dart:1257) e nunca mostra a arte do deck que anuncia — Confere em home_screen.dart:1257-1258. Abri o asset: são três cartões cinza empilhados com o logo e uma linha pontilhada, sem nada de Magic. O onboarding reaproveita o mesmo asset com Opacity 0.48 no modo compacto (onboarding_core_flow_screen.dart:604-607).
- ✅ O Acesso rápido é uma ListView horizontal com 2 itens visíveis e altura 72 (home_screen.dart:1494-1519). _QuickActionCard é uma linha com glifo de 21px e rótulo fontSm em caixa surfaceSlate com contorno hairline (1593-1647) — Confere linha a linha: visibleItemCount = maxWidth >= 520 ? 3 : 2, SizedBox(height: space72), ListView.separated com scrollDirection horizontal, ManaLoomGlyph size 21, Border.all com strokeHairline. Não tem numeral, estado nem miniatura.
- ✅ A arte do deck recente fica em 72x102 (home_screen.dart:1715-1717), a contagem '100/100' em fontXs (1777-1783) e os pips de mana em 12px (1907) — Confere: SizedBox(width: space72, height: 102), Text('${deck.cardCount}/$target') com fontSize fontXs, ColorIdentityPips(symbolSize: 12). Em produção a arte é real: CardArtwork com commanderImageUrl e fallback ScryfallImageHelper.namedImageUrl (1834-1846). A arte do golden é fixture.
- ✅ _DeckFallback (home_screen.dart:1852-1885) é um retângulo quase cinza com glifo a 26%, e isso acontece em produção para decks sem comandante — Confere, e é pior do que ele descreveu. AppTheme.identityColor (app_theme.dart:439-447) devolve manaC (cinza) para identidade vazia e frost600 (cinza-azulado) para QUALQUER deck multicolor. Um Izzet Phoenix real continuaria cinza-azulado em produção, porque só decks monocoloridos ganham tinta. Não é artefato de fixture.
- ✅ Onboarding: _GoalRail com Divider (818), ChoiceChip em Wrap (1006), DropdownButtonFormField com helperText (1018-1024), _BuildModeTile com Icons.radio_button_checked/off (1346-1347), FilledButton de largura total (1172) e caixas com Border.all(outlineMuted) (783, 980) — Todas as linhas conferem por grep. Os ícones de objetivo são Material puros: Icons.style_outlined, content_paste_go_outlined, inventory_2_outlined, sports_esports_outlined, tune_rounded (1448-1492).
- ✅ O eyebrow 'PRÓXIMO PASSO' vaza do padrão AppStateStatus.information (app_state_panel.dart:68) para o vazio de notificações (notification_screen.dart:140-147) — Confere. O AppStatePanel do vazio não passa status nem eyebrow, então cai no default information, que vira 'PRÓXIMO PASSO'. A tela irmã Mensagens usa firstUse e mostra 'PRIMEIRO PASSO'.
- ✅ O Pós-jogo tem três TextField empilhados (1272-1299), e 'Nível da mesa' é texto livre com hint listando valores fechados — Confere: hintText 'Casual, melhorada, otimizada ou cEDH' em post_game_notes_screen.dart:1286. A tela, porém, pertence a features/retention, fora da área pedida.
- ✅ A folha 'Jogar agora' é showModalBottomSheet (home_screen.dart:132) com OutlinedButton de largura total (1025) e tem copy de jargão 'Vincule uma revisão para transformar a mesa em aprendizado…' (886-890) — O modal e o botão conferem. A copy de jargão existe no código, mas só no ramo canUseDecks && canWriteLearning. A captura que ele avaliou mostra o ramo simples ('Vincule um deck para registrar a partida, ou use o modo rápido sem deck.'). O hash 'd7d1c679' que ele cita não aparece nessa captura: vem da captura do Pós-jogo. O padrão 'Revisão <hash> preservada' existe mesmo em home_screen.dart:937.
- ✅ A splash usa CircularProgressIndicator padrão de 32px (splash_screen.dart:182-190) e a arte de fundo splash_art.png é quase invisível — Confere. Abri o asset: são elipses cerca de 3-4% mais claras que o fundo e uns 10 pontinhos. Na captura parece banding de renderização.
- ✅ A barra inferior é a NavigationBar de fábrica do Material, só com glifos próprios (main_scaffold.dart:130-142) — Confere.

## Decks: lista, detalhe, criar, importar

**Auditor 4.5 → revisor 4.5** · formulário · auditor foi *justo*

Não, a área de Decks não está no nível do contador. Dou nota 4,5 de 10. Vi as 12 capturas listadas e conferi o código de cada tela; nada foi executado nem alterado.

A área se divide em dois grupos:

- **Lista e detalhe (as telas de uso diário):** estão no nível "correto-genérico". Têm arte real de carta, nome em serifada, símbolos de mana e um herói com botão dourado claro.
- **Criar, escolher comandante, importar e gerar com IA:** são formulário puro. É exatamente o que o dono chama de feio: janela cinza, campos de texto empilhados, listas suspensas, interruptores e botões largos.

A distância é de gramática visual, não de acabamento. O tema já tem a serifada Fraunces, cores por formato, glifos próprios e o componente de arte de carta. Fora da lista, quase nada disso é usado: em toda a área de Decks, a Fraunces é aplicada explicitamente em dois arquivos, `deck_list_screen.dart` e `deck_commander_selector.dart`. O nome do deck no herói do detalhe só sai serifado por herança do tema. Importar e o Gerador não têm nenhum texto serifado.

No contador, cada escolha é um objeto e o estado mora dentro dele. Aqui acontece o contrário:

- **Escolhas como texto:** as escolhas mais visuais do jogo são lista suspensa ou linha de lista. Isso vale para o formato, os brackets de 1 a 5 e o comandante.
- **Números sem expressão:** os números que importam aparecem em texto de 12 px dentro de pílulas. São a contagem 100/100, o custo médio de mana e o preço.
- **Arte em miniatura:** a arte existe, mas sempre pequena, entre 48 e 92 px. Nunca é protagonista.

Dois pontos sobre as capturas:

- **Arte de fixture:** a arte genérica que aparece em algumas capturas vem do fixture de teste, não do design. Em produção entra a arte real da carta. Mesmo assim o layout reserva pouco espaço para ela, e foi isso que puni.
- **Herói do detalhe:** a captura de 03/08 em `ux-pack-01-deck-detail-web` mostra a arte do comandante como fundo do herói, e ficou mais bonita que a versão atual. A arte do herói em miniatura de 78 px aparece no commit e6737c53b, de 10/08; o código atual só a mostra assim. Além disso, as capturas em `docs/qa/ui-live/current` estão defasadas: mostram 3 abas onde o código tem 4 e "Foil" onde o código diz "Foil disponível".

A melhor tela é a lista vazia: tem estado vazio desenhado e título serifado grande. A pior é o Gerador com IA, que tem aparência de tela de configurações.

Para chegar ao nível do contador, é preciso redesenhar as quatro telas do fluxo de criação na gramática de azulejos. No detalhe e na lista, a arte e os números precisam virar protagonistas. Os ganhos rápidos (arte de fundo, números serifados, azulejos de ação, títulos em Fraunces) levam lista e detalhe para perto de 6 ou 7. O resto é redesenho caro.

- **Melhor tela:** Lista de decks vazia (decks_empty.png) — única com composição pensada: ilustração própria com brilho, eyebrow, headline serifada grande e herói claro. Ainda assim resolve as três escolhas com botões largos empilhados e não tem arte nem mana.
- **Pior tela:** Gerador de decks com IA (core_13/core_14, deck_generate_screen.dart:1100-1332) — dois dropdowns, três campos de texto, dois switches e um botão largo; a feature mais mágica do produto é visualmente uma tela de configurações, sem serifada, sem arte, sem mana.

### Notas por tela

| Tela | Obj | Hier | Tipo | Mat | MTG | Resp | Est | 1ªimp | Média | Veredito |
|---|---|---|---|---|---|---|---|---|---|---|
| Lista de decks (1 deck, cartão spotlight) | 3 | 3 | 3 | 2 | 3 | 3 | 3 | 3 | 2.9 | correto, genérico |
| Lista de decks vazia (primeiro deck) | 3 | 4 | 4 | 3 | 2 | 4 | 4 | 3 | 3.4 | bom, abaixo do contador |
| Criar deck (modal 'Novo Deck') | 1 | 2 | 2 | 1 | 1 | 3 | 2 | 1 | 1.6 | formulário |
| Escolher comandante (dialog de busca) | 2 | 2 | 2 | 2 | 3 | 3 | 2 | 2 | 2.2 | formulário |
| Importar lista | 1 | 3 | 1 | 1 | 1 | 3 | 2 | 1 | 1.6 | formulário |
| Gerador de decks com IA (inclui menu de brackets) | 1 | 2 | 1 | 1 | 1 | 2 | 2 | 1 | 1.4 | formulário |
| Detalhe do deck — topo (Visão Geral) | 3 | 4 | 3 | 2 | 3 | 3 | 3 | 3 | 3.0 | correto, genérico |
| Detalhe do deck — abaixo da dobra | 2 | 2 | 2 | 2 | 2 | 2 | 3 | 2 | 2.1 | correto, genérico |

#### Lista de decks (1 deck, cartão spotlight)

Captura: `app/test/ui/goldens/runtime/web_mobile/decks_seeded.png`

**Problemas**

- A carta do comandante aparece (arte real via Scryfall, não é placeholder), mas como miniatura 'small' de 92px encostada à esquerda; o fundo do cartão é um glifo fantasma genérico de deck (_DeckFallbackArt em deck_list_screen.dart:1508) em vez da arte do comandante sangrando atrás. A arte não é protagonista.
- Sopa de chips dentro do cartão: 'Commander', pip de mana, '100/100', 'Validado' como quatro badges de contorno 1px (deck_list_screen.dart:1608-1623). No contador, '100' seria um numeral serifado grande; aqui é texto de 12px dentro de pílula.
- Caixa 'Ações rápidas' (deck_list_screen.dart:1345-1410) é uma caixa cinza com título e três pílulas de ícone 14px: exatamente a gramática de configurações que o dono rejeita. São as três formas de criar um deck e merecem ser azulejos.
- Material chapado: surfaceSlate + hairline; o gradiente lateral (1513-1520) é quase imperceptível. Sem profundidade, sem sombra, sem cor com significado além do verde de 'Validado'.
- Abas de filtro 'Todos 1 / Commander 1 / Padrão 0 / Outros 0' mostram zeros sem valor visual; 60% da tela fica preta vazia com um FAB solto no canto.
- Fraunces só aparece em 'Meus Decks' e no nome do deck a 18px. Nenhum contraste de escala.

**Acertos**

- Arte real de carta presente e com proporção correta de carta MTG.
- Nome do deck em serifada display; pip de mana real (não ícone genérico).
- Existe variante em grade (_DeckGalleryCard, deck_list_screen.dart:1868) com a carta ocupando a maior parte do azulejo e gradiente por formato — é a melhor ideia da área, mas não há captura dela com vários decks.

#### Lista de decks vazia (primeiro deck)

Captura: `app/test/ui/goldens/runtime/web_mobile/decks_empty.png`

**Problemas**

- As três escolhas (criar, gerar com IA, importar) são três botões largos empilhados — preenchido, contornado e link de texto. No contador seriam três azulejos com objeto visual próprio (carta em branco, varinha com brilho, lista colada).
- A constelação de cartas é desenhada sob medida, mas as cartas são silhuetas de contorno com glifo: zero arte, zero cor de mana. Identidade MTG fraca para a porta de entrada do produto.
- Metade inferior da tela vazia; o conjunto flutua no preto chapado sem superfície ou mesa atrás.

**Acertos**

- Estado vazio desenhado de verdade (eyebrow 'PRIMEIRO DECK', ilustração com brilho e anéis via CustomPainter, headline serifada grande).
- Herói e ação primária inequívocos; bom contraste de escala tipográfica.
- É a única tela da área em que alguém claramente pensou em composição antes de pensar em campos.

#### Criar deck (modal 'Novo Deck')

Captura: `app/test/ui/goldens/runtime/web_mobile/deck_create_modal.png (e core-product-android/core_05_deck_inline_validation.png)`

**Problemas**

- É literalmente a lista de rejeições do dono: showDialog + Dialog cinza (deck_list_screen.dart:119/130), TextField de nome (:205), DropdownButtonFormField de formato (:235), TextField de descrição (:305), SwitchListTile 'Deck público' (:338) e par de botões Cancelar/Criar deck (_DeckCreateDialogActions, :2647).
- Formato é a escolha mais visual possível em MTG (Commander, Standard, Modern, Pauper... cada um com cor própria já definida em AppTheme.format*) e está escondido num dropdown de texto.
- Primeira coisa que o olho vê é um contorno vermelho e 'Informe o nome do deck.' — o ponto focal da tela é um erro.
- 'Selecionar comandante' é uma linha com chevron que abre OUTRO modal por cima do modal (aninhamento que o contador proíbe).
- Campo 'Descrição (opcional)' ocupa um bloco cinza enorme e vazio no meio do modal; Fraunces só no título 'Novo Deck'.
- Nenhuma arte, nenhum símbolo de mana, nenhuma superfície com gradiente: caixa surfaceElevated com borda outlineMuted.

**Acertos**

- Funcionalmente sólido: foco, validação inline com liveRegion, scrollbar, tratamento de teclado apertado.
- A linha do comandante tem contorno latão e glifo próprio — pequeno sinal de intenção.

#### Escolher comandante (dialog de busca)

Captura: `docs/qa/ui-live/current/core-product-android/core_06_deck_commander_filtered.png`

**Problemas**

- Escolher o comandante é o momento mais emocional de montar um deck e está resolvido como campo de busca + linha de lista dentro de um Dialog cinza (deck_commander_selector.dart:386, TextField em :458).
- O quadrado escuro com glifo na captura é artefato de fixture: em produção o tile usa CardArtwork com card.effectiveImageUrl (deck_commander_selector.dart:636-640). Mas o layout reserva só 48x67 px para a arte — mesmo com arte real, ela vira um selo ao lado de três linhas de texto. Punido pelo espaço, não pelo placeholder.
- 80% do dialog é um retângulo cinza vazio abaixo do único resultado; não há estado desenhado para 'poucos resultados'.
- Serifada só no título; resultado em Inter, chevron de lista de configurações.

**Acertos**

- Símbolos de mana reais (W/R) na identidade de cor e rótulo 'Elegível como comandante' em latão — cor com significado.
- Borda latão no candidato dá um mínimo de destaque.

#### Importar lista

Captura: `app/test/ui/goldens/runtime/web_mobile/deck_import_detected.png`

**Problemas**

- Pilha de campos OutlineInputBorder com prefixIcon genérico do Material: Icons.edit, Icons.category, Icons.star, Icons.description (deck_import_screen.dart:815-882). Nem os glifos ManaLoom do próprio app são usados aqui.
- Textarea monoespaçada de 15 linhas (deck_import_screen.dart:920-937) com rótulo flutuante redundante ('Lista de Cartas' acima e 'Lista de cartas para importar' dentro).
- O único retorno visual de '1 Sol Ring' é uma tirinha '1 carta detectada' com ícone de check (:942-985). A carta reconhecida deveria aparecer como carta — o app tem CardArtwork e já o usa no preflight (:1162), mas só depois de apertar o botão.
- Zero Fraunces na tela inteira: AppBar, títulos de seção e CTA em Inter. Zero gradiente, zero profundidade.
- Botão largo 'Revisar antes de criar' + parágrafo explicativo cinza por baixo: parede de texto de rodapé.
- Helper text 'Ajuda a validar identidade de cor; também aceita [Commander] na lista.' é documentação colada na UI.

**Acertos**

- Fluxo em duas etapas (reconhecer antes de salvar) é bom produto.
- CTA latão único e claro no fim da tela.

#### Gerador de decks com IA (inclui menu de brackets)

Captura: `docs/qa/ui-live/current/core-product-android/core_14_commander_bracket_b1.png (e core_13_commander_brackets_menu.png)`

**Problemas**

- É a pior tela da área: dois DropdownButtonFormField (formato :1108, bracket :1136), três TextField (:1204, :1239, :1284), dois SwitchListTile.adaptive (:1257, :1270) e um ElevatedButton largo (:1306), todos em deck_generate_screen.dart. É uma tela de configurações.
- Brackets 1 a 5 são o candidato perfeito à gramática do contador — cinco azulejos com numeral serifado enorme '1'...'5', nome e cor própria — e viraram o popup cru padrão do Material ('1 - Exhibition', '2 - Core'...) visto em core_13.
- Rótulos com dois-pontos de formulário web: 'Formato:', 'Bracket Commander:', 'Comandante (opcional):', 'Descreva seu deck:' (:1106, :1132, :1202, :1237).
- Helper text truncado com reticências na captura ('guiar a geração por um comandant…').
- 'Ou escolha um ponto de partida' (:1938) é uma lista de links de texto com setinha; arquétipos (goblins aggro, controle azul-branco) pedem azulejos com cor de mana.
- A feature mais mágica do produto (IA monta seu deck) não tem um pixel de arte, mana, brilho ou serifada. AppBar 'Gerador de Decks' em Inter.

**Acertos**

- Orientação do bracket muda com AnimatedSwitcher e ícone de escudo — conteúdo bom, embalagem errada.
- CTA latão 'Gerar proposta' com ícone de brilho é o único ponto de cor.

#### Detalhe do deck — topo (Visão Geral)

Captura: `app/test/ui/goldens/runtime/web_mobile/deck_detail_top.png (e docs/qa/ui-live/current/ux-pack-01-deck-detail-web/deck_detail_top.png)`

**Problemas**

- Regressão de protagonismo da arte: a captura ux-pack-01 (03/08) mostra a arte do comandante sangrando como fundo do herói; o código atual e o golden de 09/09 mostram só uma miniatura de 78x109 px (deck_details_overview_tab.dart:262-265, introduzida em e6737c53b). A versão antiga era mais bonita. A evidência em docs/qa/ui-live/current está defasada em relação ao código.
- A imagem do anel na captura é arte de fixture; em produção entra a arte real via CardArtwork (:266-277). O problema é o espaço: 78 px num herói de 176 px.
- Sopa de chips no herói: COMMANDER, pip, Validado, Público (Wrap em :214-254), todos contorno 1px.
- A 'grade de resumo' não é grade de azulejos: _SummaryTile (:719-783) é ícone 18px + rótulo + valor em bodySmall, sem superfície. '100/100 cartas' e o CMC deveriam ser numerais serifados grandes; 'Curva: Aba Análise' é um não-dado ocupando um quarto do bloco.
- Caixa dentro de caixa: cartão 'Estratégia' contém outro cartão 'Não definida' com chevron e ainda um link azul por baixo (_StrategySummaryCard, :1548).
- AppBar diz 'Detalhes do Deck' (deck_details_screen.dart:426) — título genérico de CRUD em Inter, em vez do nome do deck.
- Dois botões largos empilhados (Jogar agora / Otimizar, :1429-1500).

**Acertos**

- Hierarquia clara: herói, CTA dourado 'Jogar agora', secundário 'Otimizar'.
- Nome do deck em Fraunces, cor de contorno do herói derivada do formato, verde/azul com significado nos chips de estado.
- Faixa 'Deck legal para o formato' com selo verde comunica estado de forma rápida.

#### Detalhe do deck — abaixo da dobra

Captura: `app/test/ui/goldens/runtime/web_mobile/deck_detail_below_fold.png (e ux-pack-01-deck-detail-web/deck_detail_below_fold.png)`

**Problemas**

- Rolagem de cartões cinzas de mesmo peso: Comandante, Descrição, Próximos ajustes. Nenhum ponto focal, nenhuma serifada em toda a dobra.
- Seção Comandante (_CommanderSection, deck_details_overview_tab.dart:471) trata a carta mais importante do deck como linha de lista: miniatura ~50px + três linhas de texto + chips 'TST #125' e 'Foil'.
- Descrição é caixa dentro de caixa com subtítulo explicativo ('Resumo curto do plano e da intenção do deck.') e botão 'Editar' (:1306-1427) — campo de formulário disfarçado.
- 'Próximos ajustes do deck' (deck_diagnostic_panel.dart:82) empilha título, parágrafo, chip 'Ajustes sugeridos', link 'Ver testes', e um cartão aninhado cujo título trunca ('...antes da pró…', :248). Parede de texto.
- Divergência entre capturas do mesmo estado: chip 'Foil disponível' (golden) vs 'Foil' (ux-pack-01) — evidência desatualizada.

**Acertos**

- Cor latão no contorno do alerta de ajustes tem significado.
- Espaçamento entre seções é consistente; nada está quebrado.

### Cheiros de formulário (arquivo:linha)

- `app/lib/features/decks/screens/deck_list_screen.dart:119` — Criar deck é showDialog + Dialog cinza (surfaceElevated, borda outlineMuted) — modal de formulário sobre a lista.
- `app/lib/features/decks/screens/deck_list_screen.dart:205` — TextField 'Nome do deck' com erro vermelho inline como primeiro elemento do modal.
- `app/lib/features/decks/screens/deck_list_screen.dart:235` — DropdownButtonFormField para Formato — escolha visual (cores de formato já existem no tema) escondida em dropdown de texto.
- `app/lib/features/decks/screens/deck_list_screen.dart:305` — TextField multilinha 'Descrição (opcional)' ocupando bloco cinza vazio no meio do modal.
- `app/lib/features/decks/screens/deck_list_screen.dart:338` — SwitchListTile 'Deck público / Visível na comunidade'.
- `app/lib/features/decks/screens/deck_list_screen.dart:2647` — _DeckCreateDialogActions: par de botões largos Cancelar / Criar deck no rodapé do modal.
- `app/lib/features/decks/screens/deck_list_screen.dart:1345` — _SparseDeckActions: caixa cinza 'Ações rápidas' com pílulas de ícone 14px (Criar com IA, Importar lista, Buscar cartas).
- `app/lib/features/decks/screens/deck_list_screen.dart:1608` — Wrap de quatro _DeckInfoBadge no cartão spotlight — sopa de chips; contagem '100/100' como texto de pílula.
- `app/lib/features/decks/screens/deck_list_screen.dart:1508` — Fundo do cartão spotlight é _DeckFallbackArt (glifo fantasma) mesmo quando há arte; a arte real fica restrita a 92px (linha 1539, versão 'small').
- `app/lib/features/decks/widgets/deck_commander_selector.dart:386` — Seletor de comandante é um segundo Dialog aberto por cima do modal de criação (modal aninhado), com TextField de busca na linha 458.
- `app/lib/features/decks/widgets/deck_commander_selector.dart:636` — Candidato a comandante como linha de lista com arte em 48x67 px e chevron; o layout não dá protagonismo à arte mesmo em produção.
- `app/lib/features/decks/screens/deck_import_screen.dart:815` — Pilha de quatro campos OutlineInputBorder com prefixIcon genérico do Material (Icons.edit :822, Icons.category :834, Icons.star :864, Icons.description :879).
- `app/lib/features/decks/screens/deck_import_screen.dart:828` — DropdownButtonFormField 'Formato *' com asterisco de campo obrigatório.
- `app/lib/features/decks/screens/deck_import_screen.dart:920` — Textarea monoespaçada de 15 linhas com rótulo flutuante duplicando o título da seção.
- `app/lib/features/decks/screens/deck_import_screen.dart:942` — Retorno de detecção é uma tirinha de texto '1 carta detectada' em vez de mostrar as cartas reconhecidas como cartas.
- `app/lib/features/decks/screens/deck_import_screen.dart:1266` — ElevatedButton de largura total + parágrafo explicativo cinza no rodapé (linha 1326).
- `app/lib/features/decks/screens/deck_import_screen.dart:417` — AlertDialog padrão do Material no fluxo de importação.
- `app/lib/features/decks/screens/deck_generate_screen.dart:1108` — DropdownButtonFormField de formato precedido por rótulo 'Formato:' com dois-pontos (linha 1106).
- `app/lib/features/decks/screens/deck_generate_screen.dart:1136` — DropdownButtonFormField<int> para Bracket 1-5 — abre o popup cru do Material (core_13) em vez de cinco azulejos com numeral serifado.
- `app/lib/features/decks/screens/deck_generate_screen.dart:1204` — TextField de comandante com helperText de três linhas que trunca na captura; seguido de mais um TextField de prompt (linha 1239).
- `app/lib/features/decks/screens/deck_generate_screen.dart:1257` — Dois SwitchListTile.adaptive ('Priorizar minha coleção', 'Somente cartas que possuo', linha 1270) + TextField de orçamento (linha 1284).
- `app/lib/features/decks/screens/deck_generate_screen.dart:1306` — ElevatedButton.icon de largura total 'Gerar proposta' enterrado no meio da rolagem.
- `app/lib/features/decks/screens/deck_generate_screen.dart:1938` — 'Ou escolha um ponto de partida' como lista de links de texto com setinha north_east (linha 1963).
- `app/lib/features/decks/widgets/deck_details_overview_tab.dart:262` — Arte do comandante no herói do detalhe confinada a 78x109 px; versão anterior (captura ux-pack-01 de 03/08) usava a arte como fundo.
- `app/lib/features/decks/widgets/deck_details_overview_tab.dart:719` — _SummaryTile: ícone 18px + rótulo + valor em bodySmall, sem superfície — linhas rotuladas, não azulejos; numerais sem expressão.
- `app/lib/features/decks/widgets/deck_details_overview_tab.dart:214` — Wrap de DeckMetaChip no herói (formato, pip, validação, público) — sopa de chips de contorno 1px.
- `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1548` — _StrategySummaryCard: caixa dentro de caixa com chevron e link azul explicativo.
- `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1306` — _DescriptionSection: título + subtítulo explicativo + botão Editar + caixa interna — campo de formulário disfarçado de seção.
- `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1429` — _OverviewQuickActions: dois botões largos empilhados (FilledButton 'Jogar agora' :1440, OutlinedButton 'Otimizar' :1465).
- `app/lib/features/decks/widgets/deck_diagnostic_panel.dart:82` — Painel 'Próximos ajustes do deck': título + parágrafo + chip + link + cartão aninhado cujo título trunca (linha 248) — parede de texto.
- `app/lib/features/decks/screens/deck_details_screen.dart:426` — AppBar com título genérico 'Detalhes do Deck' em vez do nome do deck; TabBar padrão (linha 562).

### Ganhos rápidos

- Devolver a arte do comandante como fundo do herói do detalhe (como na captura ux-pack-01 de 03/08) com gradiente de legibilidade, em vez da miniatura de 78 px em deck_details_overview_tab.dart:260-279.
- No cartão spotlight da lista, trocar o fundo _DeckFallbackArt (deck_list_screen.dart:1508) pela arte do comandante em art_crop desfocada/escurecida quando hasArt; manter o glifo só como fallback.
- Promover numerais: '100/100', CMC médio e preço em Fraunces grande dentro de _SummaryTile (deck_details_overview_tab.dart:768-776) e dar a cada tile uma superfície com gradiente sutil — vira grade de azulejos de verdade com pouca mudança.
- Trocar o título do AppBar 'Detalhes do Deck' (deck_details_screen.dart:426) pelo nome do deck em Fraunces; aplicar Fraunces também nos AppBars de Importar e Gerador.
- Substituir Icons.edit/category/star/description da importação (deck_import_screen.dart:822-879) pelos glifos ManaLoom já existentes e remover o rótulo flutuante duplicado da textarea (:924).
- Transformar 'Ações rápidas' (deck_list_screen.dart:1345) em três azulejos lado a lado com ícone grande, reaproveitando a estrutura do _DeckGalleryCard.
- Desaninhar 'Estratégia' e 'Descrição' no detalhe: uma superfície só por seção, sem caixa interna nem subtítulo explicativo.
- Corrigir truncamentos visíveis: título do painel de ajustes (deck_diagnostic_panel.dart:248) e helperText do comandante no gerador (deck_generate_screen.dart:1210).
- Regerar docs/qa/ui-live/current/ux-pack-01-deck-detail-web: as capturas de 03/08 não correspondem mais ao código (3 abas vs 4, herói com arte de fundo vs miniatura, 'Foil' vs 'Foil disponível').

### Redesenhos necessários

- Criar deck: abandonar o Dialog (deck_list_screen.dart:119-420) por uma superfície de tela cheia na gramática do hub do contador — azulejos de formato com a cor AppTheme.format* e ícone grande, azulejo de comandante que vira a própria carta quando escolhido, visibilidade público/privado como azulejo de estado (como COROA/INICIATIVA), nome como único campo de texto.
- Seletor de comandante: trocar Dialog + lista de linhas (deck_commander_selector.dart:386-720) por grade de cartas com arte grande (2 colunas no mobile), identidade de cor sobre a arte e estado selecionado no próprio objeto; eliminar o modal sobre modal.
- Gerador com IA: redesenho completo de deck_generate_screen.dart:1100-1332 — brackets 1-5 como cinco azulejos com numeral serifado enorme e cor própria, formato como azulejos, coleção/orçamento como azulejos de estado em vez de switches, pontos de partida como azulejos de arquétipo com cores de mana, e um herói dourado 'Gerar proposta' no padrão do PASSAR A VEZ.
- Importar lista: substituir a pilha de campos por uma superfície em que a lista colada vira cartas reconhecidas ao vivo (miniaturas com CardArtwork, contagem em numeral grande, pendências destacadas na própria carta), com metadados reduzidos a azulejos; a textarea vira área de colagem secundária.
- Detalhe do deck abaixo da dobra: trocar a rolagem de cartões cinzas por composição com âncoras visuais — comandante como carta grande, curva de mana e contagem por tipo como objetos gráficos, ajustes sugeridos como azulejos com cor de severidade em vez de parágrafos.
- Lista de decks com 1-2 decks: layout que use o espaço (carta grande com arte de fundo, azulejos de próxima ação) em vez de cartão de 184 px + caixa de pílulas + 60% de tela vazia.

### Contestação do revisor

Veredito: justo. Abri a referência do contador e 13 capturas (as 12 da lista mais o golden deck_generate_empty.png, que mostra o topo do gerador) e formei notas próprias antes de reler o auditor. Elas caíram praticamente em cima das dele: lista com deck ~2,9/5, lista vazia ~3,4, topo do detalhe ~3,0, abaixo da dobra ~2,1, comandante ~2,3, criar ~1,6, importar ~1,75, gerador ~1,5. Média ~2,3/5 = 4,5–4,7/10. Mantenho 4,5 e o nível 'formulario'.

Conferi 11 afirmações de código; 8 batem linha a linha (Dialog de criação, dropdowns, switches, fundo _DeckFallbackArt incondicional, arte 78x109 no herói e o commit e6737c53b de 10/08 que a introduziu, tile de comandante 48x67, _SummaryTile sem superfície, AppBar 'Detalhes do Deck', título truncado do painel de ajustes). A leitura dele sobre fixture vs produção está correta: a arte placeholder é artefato, em produção entra CardArtwork com imagem real, e o que ele puniu foi o espaço reservado (48–92 px), que é de fato o problema.

Três erros dele, todos pequenos e nenhum muda veredito:
1. 'Zero Fraunces' em Importar e Gerador é falso — os cabeçalhos (deck_import_screen.dart:771, deck_generate_screen.dart:1062) herdam Fraunces do tema; ele só viu capturas roladas. Tipografia dessas telas é 2, não 1.
2. O erro vermelho como 'ponto focal' do modal Novo Deck é artefato de captura: nameError só aparece após envio inválido.
3. A truncagem do helper do gerador já foi corrigida (helperMaxLines: 3); a captura Android é de 02/08 e o ganho rápido correspondente é inválido.

Na direção oposta, ele foi generoso ao rotular o detalhe abaixo da dobra como 'correto-generico' com todas as notas em 2: é uma pilha de caixas cinzas com título + subtítulo + link 'Editar/Trocar/Definir', a gramática de configurações que o dono rejeita. E perdeu que o topo do gerador é pior do que o trecho que ele viu: painel de texto 'IA assistida, decisão sua', medidor de cota e uma seção chamada literalmente 'Configuração da proposta', além de pedir o comandante duas vezes (campo de texto + seletor canônico).

Onde formulário é legítimo: a textarea de colar lista na importação e o campo de prompt do gerador são texto por natureza e não deveriam ser punidos em si; o nome do deck também. Tudo em volta deles (formato, bracket 1–5, comandante, público/privado, coleção/orçamento, pontos de partida) são escolhas visuais resolvidas como dropdown, switch e linha de lista — a crítica central do auditor está certa.

Resposta à pergunta do dono para esta área: não, o cuidado visual não está no nível do contador. Lista e topo do detalhe são corretos porém genéricos (arte real, serifada no nome, CTA dourado, mas arte em miniatura, numerais em pílulas de 12px, material chapado). Todo o fluxo de criação (criar, escolher comandante, importar, gerar com IA) é formulário puro dentro de Dialog ou pilha de campos. A única tela com composição pensada é o estado vazio da lista. As capturas em docs/qa/ui-live/current (ux-pack-01 de 03/08 e core-product-android de 02/08) estão defasadas em relação ao código e devem ser regeneradas antes de servir de evidência.

Arquivos relevantes: /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app/lib/features/decks/screens/deck_list_screen.dart, .../screens/deck_generate_screen.dart, .../screens/deck_import_screen.dart, .../screens/deck_details_screen.dart, .../widgets/deck_details_overview_tab.dart, .../widgets/deck_commander_selector.dart, .../widgets/deck_diagnostic_panel.dart, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app/lib/core/theme/app_theme.dart.

**Discordâncias**

- **Criar deck (modal Novo Deck)** — auditor: O ponto focal da tela é um erro vermelho ('Informe o nome do deck.'). · revisor: Duro demais neste item: é artefato das duas capturas, ambas tiradas depois de um envio inválido (core_05 = 'inline_validation'). No código nameError começa null (deck_list_screen.dart:116) e só aparece após submit. Hierarquia sem o erro seria 2-3, não muda o veredito 'formulario' — o resto da crítica (Dialog, dropdown de formato, switch, modal sobre modal, bloco de descrição vazio) está correto e eu vi o mesmo.
- **Importar lista** — auditor: Tipografia 1: 'Zero Fraunces na tela inteira'. · revisor: Erro factual por captura rolada: o cabeçalho fora do quadro usa titleLarge = Fraunces (deck_import_screen.dart:771). Tipografia 2. Além disso, aqui o formulário é parcialmente legítimo: colar uma lista de texto É a tarefa, então a textarea monoespaçada em si não merece punição. O que merece é tudo em volta: quatro campos com Icons.edit/category/star/description, rótulo duplicado, retorno '1 carta detectada' como tirinha em vez de cartas. Veredito 'formulario' se mantém, com média ~1,75 em vez de 1,6.
- **Gerador de decks com IA** — auditor: Tipografia 1, 'sem um pixel de serifada'; helper text truncado como problema e como ganho rápido. · revisor: Dois erros pequenos: 'Gerar Deck' é serifado (headlineSmall, :1062, visível em deck_generate_empty.png) e a truncagem do helper já foi corrigida (helperMaxLines: 3, :1212) — a captura Android é de 02/08. Tipografia 2. Por outro lado o campo de prompt é texto legítimo (descrever o deck para a IA). Mesmo assim concordo que é a pior tela: o topo que o auditor não viu é ainda mais 'configurações' do que o trecho que ele viu (ver problemas perdidos). Nota da tela fica praticamente igual (~1,5).
- **Detalhe do deck — abaixo da dobra** — auditor: Notas todas em 2 (média 2,1) mas veredito 'correto-generico'. · revisor: Generoso no rótulo, incoerente com as próprias notas. O que vi é exatamente a gramática que o dono rejeita: pilha de caixas cinzas de mesmo peso, cada uma com título + subtítulo explicativo + link de ação à direita (Trocar / Editar / Definir) e caixa dentro de caixa — é uma tela de configurações sem campos de entrada. Eu classificaria como 'formulario' no sentido do dono. Isso reforça, não enfraquece, o nível 'formulario' da área.
- **Escolher comandante** — auditor: Estados 2: 'não há estado desenhado'. · revisor: Levemente duro: existem estados vazio/erro desenhados com glifo ManaLoom e cor de aviso (_CommanderPickerMessage, deck_commander_selector.dart:525-533). O que falta é só o caso 'poucos resultados' deixando 80% do dialog vazio. Estados 3. Veredito não muda.
- **Nível da área** — auditor: nota 4,5/10 com nível 'formulario'. · revisor: A aritmética dele confere (média das 8 telas = 2,28/5 = 4,56/10; com meus ajustes dá ~2,33/5). Numericamente 2,3 fica um pouco mais perto de 'correto-generico' (3) do que de 'formulario' (1), então o rótulo é limítrofe. Mantenho 'formulario' porque 4 das 8 superfícies são formulário puro e uma quinta (detalhe abaixo da dobra) é gramática de configurações — ou seja, a maioria seria rejeitada pelo dono. Mas o leitor deve guardar a divisão: lista e topo do detalhe = correto-genérico (~3/5); todo o fluxo de criação = formulário (~1,5/5).

**Problemas que o auditor perdeu**

- Topo do Gerador com IA (golden deck_generate_empty.png, que existe na mesma pasta mas não estava na lista): antes de qualquer escolha o usuário atravessa um parágrafo introdutório, uma caixa 'IA assistida, decisão sua' com 4 linhas de texto quase jurídico (_AiTrustPanel, deck_generate_screen.dart:2195/2234, montado em :1084) e um medidor de cota 'Ações de IA · Beta gratuita · 0 de 120 usadas' (AiUsageMeter, :1086). Só depois vem o título de seção que literalmente se chama 'Configuração da proposta' (:1100). Parede de texto + medidor + 'Configuração': o primeiro segundo da feature mais mágica é aviso e burocracia.
- Gerador: o comandante agora é pedido DUAS vezes em sequência — um TextField de nome (:1204) e logo abaixo um DeckCommanderSelector 'Carta canônica do comandante' (:1222-1233) com subtítulo explicando por que o primeiro campo não basta. Dois controles para a mesma decisão, e o segundo abre o mesmo Dialog de lista. O formulário ficou mais longo desde as capturas Android de 02/08.
- Importar: o cabeçalho fora do quadro tem sopa de chips não interativos — três _ImportSourcePill ('Moxfield / Archidekt / EDHRec', 'MTGA / MTGO', 'Texto simples', deck_import_screen.dart:794-796) — mais ícone genérico Icons.content_paste_rounded de 20px. É documentação em forma de pílula.
- Lista com 1 deck: quatro faixas de cromo de gestão antes do primeiro conteúdo (busca, botão de filtro, abas com contadores, linha '1 deck criado · 0 incompletos'). Para quem tem um deck, a tela abre como painel administrativo; o auditor citou só os zeros das abas.
- Cartão spotlight: o _DeckFallbackArt incondicional (deck_list_screen.dart:1507-1509) não é só 'oportunidade perdida de arte' — na captura o glifo fantasma fica atrás dos chips 'Validado'/'100/100' e da linha 'agora', competindo com o texto. É ruído, não textura.
- Evidência defasada também em core-product-android (02/08), não só em ux-pack-01: o gerador atual tem helper diferente, seletor canônico adicional e cabeçalho/medidor que essas capturas não mostram. Três dos quatro core_* da área retratam telas que já mudaram; conclusões tiradas só delas (ex.: truncagem) precisam ser revalidadas.
- Chip 'Público' do herói do detalhe é na verdade um controle (onTogglePublic, deck_details_overview_tab.dart:240-254) visualmente idêntico aos chips informativos ao lado — estado mora no objeto (bom), mas nada indica que é tocável (ruim). O auditor tratou tudo como sopa de chips sem notar que um deles é botão disfarçado.

**Afirmações de código conferidas**

- ✅ deck_list_screen.dart:119/130/205/235/305/338 — criar deck é showDialog + Dialog com TextField, DropdownButtonFormField, TextField de descrição e SwitchListTile — Todas as linhas batem exatamente (grep confirma 119 showDialog, 130 Dialog, 205 TextField, 235 Dropdown, 305 TextField, 338 SwitchListTile; _DeckCreateDialogActions em 2647).
- ✅ deck_list_screen.dart:1508 — fundo do cartão spotlight é _DeckFallbackArt mesmo quando há arte; arte real restrita a 92px — Linhas 1507-1509 têm Positioned.fill(_DeckFallbackArt) incondicional; a arte real entra só no Positioned left:12 com width: 92 (linhas 1524-1539). O glifo fantasma fica inclusive atrás dos chips, o que na captura vira ruído visual.
- ✅ deck_details_overview_tab.dart:262-265 — arte do herói confinada a 78x109, introduzida no commit e6737c53b; captura ux-pack-01 de 03/08 mostrava arte como fundo — SizedBox 78x109 com key deck-overview-hero-art-frame confere; git log -S aponta e6737c53b (2026-08-10). Abri as duas capturas: a de 03/08 realmente tem a arte sangrando no herói e 3 abas; o golden atual tem miniatura e 4 abas.
- ✅ deck_commander_selector.dart:636-640 — candidato usa CardArtwork com effectiveImageUrl em 48x67; o quadrado escuro da captura é artefato de fixture — Confere (SizedBox 48x67 + CardArtwork + errorPlaceholder _CommanderArtworkFallback). Existe um GridView de 2 colunas (linha 549), mas ele reutiliza o mesmo tile de linha com mainAxisExtent 136 — não é grade de arte, então a crítica se mantém.
- ✅ deck_details_overview_tab.dart:719 — _SummaryTile é ícone 18px + labelSmall + bodySmall, sem superfície — Confere literalmente: Padding + Row, IconThemeData size 18, valor em bodySmall w800, nenhum Container/decoration.
- ✅ deck_details_screen.dart:426 — AppBar com título fixo 'Detalhes do Deck'; AppBar em Inter — Confere; appBarTheme.titleTextStyle usa uiFontFamily (app_theme.dart:614-619).
- ❌ Importar e Gerador não têm nenhum texto serifado ('Zero Fraunces na tela inteira', 'sem um pixel de serifada') — Falso. deck_import_screen.dart:771 usa titleLarge e deck_generate_screen.dart:1062 usa headlineSmall; ambos são mapeados para Fraunces no tema (app_theme.dart:517-527). O golden deck_generate_empty.png mostra 'Gerar Deck' serifado. O auditor só viu capturas roladas para baixo do cabeçalho. A crítica de fundo (um único título serifado, zero contraste de escala, AppBar em Inter) continua válida, mas tipografia dessas telas é 2, não 1.
- ❌ deck_generate_screen.dart:1204/1210 — helperText do comandante trunca com reticências — Defasado. O código atual tem outro texto e helperMaxLines: 3 (linha 1212); o golden de 09/09 mostra o helper quebrando em 3 linhas sem truncar. A truncagem só existe na captura Android de 02/08. O 'ganho rápido' correspondente já está feito.
- ❌ Modal Novo Deck: 'primeira coisa que o olho vê é um contorno vermelho — o ponto focal da tela é um erro' — Artefato de captura. nameError nasce null (deck_list_screen.dart:116) e só é preenchido após tentativa de envio; core_05 chama-se literalmente 'deck_inline_validation' e o golden também foi tirado nesse estado. Ao abrir, o modal não tem erro. Não muda o veredito (continua formulário em Dialog), mas esse problema específico não é do design.
- ✅ deck_diagnostic_panel.dart:248 — título do aviso trunca ('...antes da pró…') — String 'Ajustes recomendados antes da próxima partida' na linha 249; truncagem visível no golden atual de 09/09, então este é válido (ao contrário do helper do gerador).
- ✅ Fraunces aplicada explicitamente só em deck_list_screen.dart e deck_commander_selector.dart — grep -l displayFontFamily em features/decks retorna exatamente esses dois arquivos. Os demais usos são herança de headlineSmall/titleLarge do tema.

## Oficina de deck: gerador IA, otimização, trocas pareadas, mão de exemplo, histórico

**Auditor 3.5 → revisor 4** · formulário · auditor foi *justo*

Não. A Oficina de deck não está no nível do contador — está longe, em torno de 3,5/10, e a distância é de gramática, não de acabamento. O contador trata cada escolha como objeto (tile, miniatura, numeral serifado, estado dentro do objeto, um herói dourado, tudo visível). A oficina trata as duas funcionalidades-vitrine — gerar deck com IA e revisar a otimização — como formulário e como modal: o gerador é uma pilha de dropdowns, campos de texto com rótulo em dois-pontos e switches, com disclaimer e barra de cota na primeira dobra e o deck gerado exibido como lista de texto '1x Nome'; a revisão da otimização é um AlertDialog rolável com caixas cinza de 1px aninhadas em até quatro níveis, checkboxes, metadados concatenados com ' • ', números-chave (9 → 36 terrenos, CMC 5.0 → 2.11) em texto de corpo e três botões empilhados comendo o rodapé. O mais grave para um app de Magic: nas trocas de carta a arte não aparece — conferi no código que não é artefato de fixture (em produção CardArtwork carrega arte real do Scryfall); o layout simplesmente não reserva espaço para ela e a esconde atrás de um ícone de 20px. O sucesso da otimização é só uma SnackBar (a tela preta da captura core_11 é casca de teste, não produção). Há sinais do caminho certo: o leitor de carta é bom (a carta é protagonista), o histórico já desenha o par SAI→ENTRA com miniaturas, a prévia de importação tem uma faixa de cartas com arte, a Fraunces aparece nos títulos e as cores têm significado (vermelho sai, verde entra, brass aprovado). Mas as miniaturas são minúsculas (34x48, 74x104), a serifada nunca é usada em numerais, o material é chapado e os estados vazio/carregando/sucesso são genéricos. Resumo honesto: funciona, é coerente na paleta e passa em teste de layout, mas é exatamente a superfície 'configurações/modal' que o dono chama de feia. Os ganhos rápidos (miniatura nas linhas de troca, tiles de numeral, herói único no rodapé, bracket em tiles) sobem a área para ~5,5; chegar ao nível do contador exige redesenhar a revisão de otimização como mesa de trocas em tela cheia e o gerador como prancha de composição.

- **Melhor tela:** Leitor de carta (deck_workshop_05_card_reader.png e optimization-card-reader-web/02_full_reader.png) — a carta é protagonista, um único X, identidade MTG máxima. Entre as telas 'de trabalho', o Histórico da oficina (deck_workshop_06) é a melhor: pares SAI→ENTRA com miniatura real e título serifado.
- **Pior tela:** Gerador de Decks (deck_generate_empty.png) empatado com a prévia de otimização em modal (core_09/core_10 e deck_workshop_02_sources.png): dropdowns, campos, switches, caixas cinza aninhadas e paredes de texto — exatamente a superfície 'configurações' que o dono chama de feia, nas duas funcionalidades-vitrine da área.

### Notas por tela

| Tela | Obj | Hier | Tipo | Mat | MTG | Resp | Est | 1ªimp | Média | Veredito |
|---|---|---|---|---|---|---|---|---|---|---|
| Gerador de Decks (vazio, com comandante, learning reads off) | 1 | 2 | 2 | 1 | 2 | 2 | 2 | 1 | 1.6 | formulário |
| Importar Lista — prévia antes de criar | 3 | 3 | 2 | 2 | 3 | 3 | 3 | 3 | 2.8 | correto, genérico |
| Prévia de otimização — referências meta / fontes (modal) | 1 | 2 | 2 | 2 | 1 | 1 | 2 | 1 | 1.5 | formulário |
| Trocas pareadas e seleção parcial (modal) | 2 | 2 | 2 | 2 | 1 | 1 | 3 | 2 | 1.9 | formulário |
| Leitor de carta (mobile) e hover/leitor (web desktop) | 4 | 4 | 3 | 3 | 5 | 4 | 3 | 4 | 3.8 | bom, abaixo do contador |
| Histórico da oficina — desfazer e conflito | 3 | 3 | 3 | 2 | 3 | 3 | 3 | 3 | 2.9 | correto, genérico |
| Mão de exemplo — playtest rápido | 3 | 3 | 2 | 2 | 3 | 3 | 2 | 2 | 2.5 | correto, genérico |
| Deck em construção (vazio) e menu de ações | 2 | 3 | 3 | 2 | 1 | 3 | 2 | 2 | 2.2 | correto, genérico |
| Prévia de otimização no Android — preview seguro e seleção parcial | 1 | 2 | 2 | 2 | 1 | 2 | 2 | 1 | 1.6 | formulário |
| Otimização aplicada (resultado) | 1 | 2 | 1 | 1 | 1 | 3 | 1 | 1 | 1.4 | formulário |

#### Gerador de Decks (vazio, com comandante, learning reads off)

Captura: `app/test/ui/goldens/runtime/web_mobile/deck_generate_empty.png ; docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-mobile/deck_workshop_00_commander.png ; .../deck_workshop_11_learning_reads_off.png`

**Problemas**

- A primeira dobra inteira é aviso e medidor: painel 'IA assistida, decisão sua' + barra 'Ações de IA 0%' vêm ANTES de qualquer escolha (deck_generate_screen.dart:1030 e 1084-1086). O usuário abre a tela mais 'mágica' do app e vê um disclaimer e uma barra de cota.
- Tudo é campo empilhado com rótulo terminado em dois-pontos ('Formato:', 'Bracket Commander:', 'Comandante (opcional):', 'Descreva seu deck:'): dois DropdownButtonFormField (linhas 1108 e 1136), três TextField (1204, 1239, 1284) e dois SwitchListTile (1257, 1270). É exatamente a superfície 'configurações' que o dono rejeita.
- Bracket 1-5 é o candidato perfeito a numerais serifados em tiles (como o '4' e o '40' do contador) e está num dropdown com uma linha de texto cinza embaixo.
- CTA 'Gerar proposta' é uma barra dourada fina (padding vertical 14) enterrada no meio da rolagem, com o mesmo peso visual dos campos; não há herói (linha 1306).
- 'Ou escolha um ponto de partida' são 6 linhas de texto cinza 12px com uma setinha de 14px (linhas 1950-1982). Arquétipos de Magic (goblins, controle UW, elfos, zumbis) sem um único símbolo de mana ou arte.
- O comandante selecionado aparece como miniatura de ~46px com dois botões de texto 'Remover'/'Trocar' — a arte do comandante deveria ser o herói da tela e ocupa menos área que o switch.
- Conferido no código (sem captura): o resultado da geração é uma lista de texto '1x Nome da carta' (linhas 1632 e 1647-1658) dentro de caixa chapada com contorno hairline (1512-1520). O momento de maior encantamento do fluxo — a IA montou seu deck — não mostra nenhuma arte de carta.
- Progresso de geração = CircularProgressIndicator + LinearProgressIndicator + chips de etapa (linhas 2106, 2121, 2141). O texto 'Tecendo lista' é bom, o desenho é genérico.

**Acertos**

- Título 'Gerar Deck' usa a Fraunces e o ícone brass; é o único momento tipográfico da tela.
- O seletor canônico de comandante (DeckCommanderSelector) mostra arte real, tipo e identidade de cor com símbolos de mana — a intenção certa, só que em escala de linha de lista.
- Em produção a arte é real (CardArtwork/Scryfall com fallback por nome); a arte sintética da captura é do fixture.

#### Importar Lista — prévia antes de criar

Captura: `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-mobile/deck_workshop_01_import_preflight.png`

**Problemas**

- Três chips de contagem ('4 reconhecidas', '1 localizadas', '1 não identificadas') que seriam numerais grandes no idioma do contador; aqui são pílulas de 13px.
- Caixa dentro de caixa: cartão da prévia contém a faixa de cartas e outro cartão 'REVISAR ANTES DE CRIAR' com contorno de 1px.
- Nenhuma serifada display na tela; o título 'Prévia pronta para sua decisão' é sans bold comum.
- A carta não identificada é só uma linha de texto com bullet — não há objeto visual para o problema (ex.: um slot de carta vazio/tracejado como o tile INICIATIVA 'sem dono').

**Acertos**

- Faixa horizontal 'CARTAS RECONHECIDAS' com arte grande (deck_import_screen.dart:1136-1162) — é a única tela do fluxo de entrada em que a carta é protagonista.
- CTA único, largo e dourado, com a frase de segurança logo abaixo; hierarquia clara.
- Cor com significado (verde reconhecida, azul localizada, âmbar pendente).

#### Prévia de otimização — referências meta / fontes (modal)

Captura: `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-mobile/deck_workshop_02_sources.png`

**Problemas**

- É um AlertDialog (deck_optimize_sheet_widgets.dart:684) com SingleChildScrollView dentro (716-718). Em 390px o diálogo fica com ~310px e, depois de três níveis de caixa aninhada (diálogo > DialogSectionCard > cartão de shell), sobra uma coluna de ~230px de texto.
- Parede de texto: parágrafo explicativo + chips + 'Shells de referência' + 'Sugestões com evidência meta' — tudo em caixas cinza com contorno de 1px (seção em :1363, cartões em :1404+).
- Rodapé com três ações empilhadas à direita ('Cancelar', 'Compartilhar relatório', 'Aplicar mudanças' — linhas 1116-1136) consome ~140px fixos; a área útil de leitura é ~560px de 844.
- Zero identidade MTG: 'Arcane Signet' e 'Lorehold historic shell' são só texto; nenhum símbolo, nenhuma arte.
- Conteúdo cortado no meio ('Antes vs Depois' decapitado pela borda do rodapé) — sensação de janela apertada, não de superfície desenhada.

**Acertos**

- Título do diálogo em Fraunces com selo de ícone frost — cabeçalho tem alguma presença.
- Chip 'Commander Bracket 3' em brass tem cor com significado.

#### Trocas pareadas e seleção parcial (modal)

Captura: `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-mobile/deck_workshop_03_paired_swaps.png ; .../deck_workshop_04_partial_selection.png`

**Problemas**

- A troca de uma carta por outra é o gesto mais visual possível em Magic e está desenhada como duas caixas de texto empilhadas: '_SelectableSuggestionLineItem' só tem nome + metadados + motivo (deck_optimize_sheet_widgets.dart:2692-2733). A arte só existe atrás de um IconButton 'style_outlined' de 20px (:2748) ou long-press — conferi: não é artefato de fixture, o layout simplesmente não reserva espaço para a arte.
- Checkbox Material cru como controle de aprovação (:2175 e :2679), quando o próprio tile já é clicável (InkWell :2656-2660). No contador o estado mora no objeto; aqui mora num quadradinho.
- Sopa de metadados truncada: 'Ramp lento • Prioridade alta • Risc…' e 'Mind Stone • HIGH 88%' — jargão de máquina concatenado com ' • ' (:2621-2639). O '88%' merecia ser numeral, está colado ao nome.
- Texto do motivo aparece duas vezes (dentro da caixa ENTRA e de novo abaixo da troca, :2264).
- Na seleção parcial (captura 04) a primeira dobra é um parágrafo de aviso + outro parágrafo explicando trocas pareadas antes de qualquer carta.
- Quatro níveis de aninhamento: diálogo > seção > cartão da troca > caixa SAI/ENTRA, todos com contorno de 1px.

**Acertos**

- O conceito SAI (vermelho) → seta → ENTRA (verde) com rótulo 'TROCA 1 · Aprovada / Fora do plano' é semanticamente correto e o estado desmarcado dessatura o par inteiro — cor com significado e estado dentro do objeto, na direção certa.
- Layout responsivo já prevê lado a lado acima de 650px (:2222).

#### Leitor de carta (mobile) e hover/leitor (web desktop)

Captura: `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-mobile/deck_workshop_05_card_reader.png ; docs/qa/ui-live/current/optimization-card-reader-web/01_hover_card.png ; .../02_full_reader.png`

**Problemas**

- É a melhor superfície da área justamente porque é quase só a carta — o mérito é da arte, não do chrome: o invólucro continua sendo folha cinza com cabeçalho ícone+título+✕ genérico.
- Dica 'Use dois dedos para ampliar e ler a carta.' em texto cinza solto sob a arte.
- No desktop (01_hover_card) a carta linda flutua ao lado de linhas de checkbox com duas linhas de altura e só o nome — o contraste escancara o quanto a lista é pobre.

**Acertos**

- Arte ocupa ~60% da tela no mobile; custo de mana e tipo com símbolos reais; chip de edição 'CMM #396'.
- Hover preview com elevação 20 e animação de escala (deck_optimize_sheet_widgets.dart:2776-2793) — há profundidade real aqui.
- Um único ✕, sem ações concorrentes.

#### Histórico da oficina — desfazer e conflito

Captura: `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-mobile/deck_workshop_06_history_undo.png ; .../deck_workshop_07_conflict.png`

**Problemas**

- Miniaturas das trocas são 34x48 (deck_workshop_tab.dart:696-698) — viram selo ilegível; o par SAI→ENTRA com arte é a melhor ideia da área e está em escala de ícone.
- Três chips empilhados ('Legalidade validada', '2 referências externas', 'Teste em jogo pendente') + botão contornado 'Desfazer aplicação' — sopa de pílulas em coluna.
- 'A proposta só termina na mesa' é um cartão de texto com dois TextButton (:742-811); 'Testar mão inicial' e 'Abrir Battle' são exatamente o tipo de escolha que o contador resolveria com dois tiles grandes.
- Metade inferior da tela vazia e preta; nada de superfície viva.
- Carregando = CircularProgressIndicator centralizado (:871); vazio = ícone genérico + texto + OutlinedButton (:815-861).
- Herói da oficina (conferido no código, :137-293): arte do comandante a 92x128 encostada à direita, 3 chips e 2 botões — gradiente de brass a 4,5% de alfa, praticamente chapado.

**Acertos**

- Título 'Histórico da oficina' em Fraunces; linha do tempo com ponto dourado dá estrutura.
- Pares SAI→ENTRA com miniatura real de carta e rótulo colorido — aqui a troca É um objeto visual (o que o modal de otimização não faz).
- Estado de conflito desenhado: faixa vermelha com 'Tentar' e explicação inline no evento, sem modal.

#### Mão de exemplo — playtest rápido

Captura: `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-mobile/deck_workshop_08_sample_hand_continuity.png`

**Problemas**

- Uma mão de 7 cartas mostrada como carrossel de cartas de 74x104 (sample_hand_widget.dart:238-239) em que só UMA carta aparece inteira e duas cortadas; o lado esquerdo do carrossel fica vazio. Contradiz o princípio 'tudo visível de uma vez' — avaliar keep/mulligan exige ver as 7.
- ~55% da tela é preto vazio abaixo do cartão, enquanto as cartas estão em tamanho de miniatura.
- Nomes truncados ('Countersp…', 'Deflecting…', 'Aca…') sob as cartas.
- Caixa chapada com contorno de 1px (:257), aviso azul em caixa, cartão de detalhe 'Counterspell / FIX #2 / Uncommon' em outra caixa — três caixas cinza empilhadas.
- Keep e Mulligan são dois botões largos empilhados (:542-566) — decisão binária que pedia dois tiles lado a lado com peso e cor.
- Sem serifada, sem numeral expressivo ('7 cartas' em cinza 12px no canto).

**Acertos**

- Usa arte real de carta como conteúdo principal; carta focada ganha escala.
- A regra de esconder a leitura automática até o jogador decidir é boa UX e está comunicada.

#### Deck em construção (vazio) e menu de ações

Captura: `docs/qa/ui-live/current/ux-pack-03-deck-workshop-web-mobile/deck_workshop_09_replace_all_off_empty.png ; .../deck_workshop_10_replace_all_off_menu.png`

**Problemas**

- Estado vazio genérico: selo de ícone 'sparkles' + título + parágrafo + botão largo + botão contornado (deck_details_overview_tab.dart:1743). Nenhum slot de comandante desenhado (silhueta de carta tracejada seria o equivalente ao tile INICIATIVA 'sem dono').
- Cabeçalho do deck é uma caixa cinza grande com 60% de área morta, '0 cartas' em 12px e três chips.
- Metade inferior da tela vazia, com uma linha de texto cinza solta.
- Menu de ações é o PopupMenu padrão do Material (lista de ícone+texto).

**Acertos**

- 'Deck em construção' em Fraunces tem presença.
- Uma ação primária clara ('Selecionar comandante') e uma secundária discreta.

#### Prévia de otimização no Android — preview seguro e seleção parcial

Captura: `docs/qa/ui-live/current/core-product-android/core_09_optimization_safe_mana_preview.png ; .../core_10_optimization_partial_selection.png`

**Problemas**

- Os números que contam a história ('Terrenos 9 → 36', 'CMC médio 5.0 → 2.11') são texto de corpo 14px alinhado à direita em linhas rotuladas dentro de caixas (_MetricDiffRow, deck_optimize_sheet_widgets.dart:1821-1855). No contador isso seria um numeral serifado enorme.
- Listas 'Remover (1/2)' e 'Adicionar (1/28)' são linhas de checkbox com altura para duas linhas e só o nome da carta — espaço morto dentro de cada linha e nenhuma arte ('Plains x27' como linha de checkbox).
- 'Curva: -' aparece como linha vazia — dado ausente renderizado cru.
- Rodapé com três ações empilhadas ocupa ~19% da altura do aparelho; o conteúdo rola numa janela de ~57%, com seções cortadas em cima e embaixo.
- Tudo é caixa surfaceSlate com borda de 1px a 20% de alfa (DialogSectionCard, deck_ui_components.dart:80-89) — sem gradiente, sem profundidade, sem mesa viva por trás (fundo preto).

**Acertos**

- Bloco 'Validação da recomendação' com selos coloridos (verde/âmbar) e título+mensagem é legível e bem espaçado.
- Item selecionado tinge a linha (vermelho para sair, verde para entrar) — cor com significado.

#### Otimização aplicada (resultado)

Captura: `docs/qa/ui-live/current/core-product-android/core_11_optimization_applied.png`

**Problemas**

- Atenção: a tela preta com '2 mudanças aplicadas' + botão 'Revisar otimização' é casca do teste de aceitação (app/integration_test/core_product_acceptance_runtime_test.dart:435-445), não é tela de produção — não punir o design por ela.
- O que É de produção na captura: o sucesso da otimização é apenas uma SnackBar 'Otimização aplicada com sucesso! Desfazer' (deck_optimize_dialogs.dart:232). O clímax do fluxo (a IA melhorou meu deck) não tem estado desenhado: sem antes/depois em numerais, sem as cartas que entraram, sem celebração.
- 'Desfazer' — ação de segurança importante — vive num toast que desaparece.

**Acertos**

- SnackBar em brass com ação 'Desfazer' é coerente com a paleta e oferece reversão imediata.

### Cheiros de formulário (arquivo:linha)

- `app/lib/features/decks/screens/deck_generate_screen.dart:1108` — DropdownButtonFormField 'Formato:' com rótulo em dois-pontos acima — campo de cadastro; deveria ser tiles de formato.
- `app/lib/features/decks/screens/deck_generate_screen.dart:1136` — DropdownButtonFormField do Bracket 1-5 + linha de orientação cinza; candidato óbvio a numerais serifados em tiles.
- `app/lib/features/decks/screens/deck_generate_screen.dart:1204` — TextField 'Comandante (opcional)' com helperText de 3 linhas, redundante com o DeckCommanderSelector logo abaixo (1222).
- `app/lib/features/decks/screens/deck_generate_screen.dart:1257` — Dois SwitchListTile.adaptive ('Priorizar minha coleção' / 'Somente cartas que possuo', 1257 e 1270) + TextField de orçamento (1284) — bloco 'configurações' puro.
- `app/lib/features/decks/screens/deck_generate_screen.dart:1306` — CTA 'Gerar proposta' como ElevatedButton largo e fino no meio da rolagem; sem herói.
- `app/lib/features/decks/screens/deck_generate_screen.dart:1030` — _AiTrustPanel + AiUsageMeter (1084-1086) renderizados antes do formulário no mobile: a primeira dobra é disclaimer e barra de cota.
- `app/lib/features/decks/screens/deck_generate_screen.dart:1647` — Deck gerado pela IA exibido como lista de Text '1x Nome' (1632 comandante, 1647-1658 cartas) em caixa chapada com contorno hairline (1512-1520); nenhuma arte.
- `app/lib/features/decks/screens/deck_generate_screen.dart:1950` — Pontos de partida como linhas de texto bodySmall cinza com seta de 14px (1950-1982); sem mana, sem arte, sem tile.
- `app/lib/features/decks/screens/deck_generate_screen.dart:2106` — Estado de geração = CircularProgressIndicator + LinearProgressIndicator (2121) + chips de etapa; carregando genérico.
- `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:684` — Toda a revisão da otimização vive num AlertDialog com SizedBox(width:560)+SingleChildScrollView (716-718): modal rolável com conteúdo cortado nas bordas.
- `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:1116` — Três ações de diálogo empilhadas (Cancelar / Compartilhar relatório / Aplicar mudanças, 1116-1136) ocupando ~140-380px fixos do rodapé.
- `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:2175` — Checkbox Material como controle de aprovação da troca pareada; outro em 2679 nas listas Remover/Adicionar, embora o tile já seja clicável (2656-2660).
- `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:2692` — _SelectableSuggestionLineItem é só texto (nome + metadados ' • ' + motivo, 2692-2733); arte escondida atrás de IconButton de 20px (2748). O layout não reserva espaço para a carta.
- `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:1821` — _MetricDiffRow: 'rótulo ........ 9 → 36' em texto de corpo; dados-herói tratados como linha de tabela.
- `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart:1363` — Seção 'Referências meta usadas': parágrafo + chips + cartões de shell aninhados (1404) — parede de texto em caixas.
- `app/lib/features/decks/widgets/deck_ui_components.dart:80` — DialogSectionCard: surfaceSlate chapado + borda de 1px a 20% de alfa, usado como contêiner universal → caixa dentro de caixa dentro de caixa em todo o fluxo.
- `app/lib/features/decks/widgets/deck_optimize_sections.dart:42` — Folha de configuração da otimização (sem captura, conferida no código): Dropdown de bracket (42-64), SwitchListTile 'Manter tema' (82), switches de coleção/orçamento (137, 148), Slider (168) e Dropdown 'Intenção do rebuild' (181-207). É uma tela de ajustes literal.
- `app/lib/features/decks/widgets/deck_optimize_dialogs.dart:232` — Sucesso da otimização = SnackBar com 'Desfazer'; sem estado de resultado desenhado.
- `app/lib/features/decks/widgets/deck_workshop_tab.dart:871` — Carregando histórico = CircularProgressIndicator; vazio = ícone+texto+OutlinedButton (815-861).
- `app/lib/features/decks/widgets/deck_workshop_tab.dart:696` — Miniaturas do histórico a 34x48; herói da oficina com arte 92x128 lateral, 3 chips (192-215) e 2 botões (217-233); trilho de etapas como texto numerado (314-327).
- `app/lib/features/decks/widgets/deck_workshop_tab.dart:793` — 'Testar mão inicial' e 'Abrir Battle / replays' como TextButton.icon dentro de cartão de texto (742-811).
- `app/lib/features/decks/widgets/sample_hand_widget.dart:238` — Cartas da mão a 74x104 em carrossel de uma carta por vez; caixa chapada 1px (257); Mulligan/Keep como botões largos empilhados (542-566).
- `app/lib/features/decks/widgets/deck_details_overview_tab.dart:1743` — Estado vazio do deck: selo de ícone genérico + parágrafo + botão largo; sem slot visual de comandante.

### Ganhos rápidos

- Colocar miniatura de carta dentro de _SelectableSuggestionLineItem (deck_optimize_sheet_widgets.dart:2675): o loadCard/Future já existe e o padrão CardArtwork+namedImageUrl já é usado em _HistoryCardRef; trocar o IconButton 'style_outlined' pela própria miniatura (56x78) como alvo de toque do leitor.
- Remover os Checkbox (2175, 2679) e fazer o tile inteiro carregar o estado (borda brass + selo de check / dessaturado 'fora do plano') — o InkWell de toggle já existe em 2656.
- Transformar _MetricDiffRow (1821) em 2-3 tiles de numeral: '9 → 36' e '5.0 → 2.11' em Fraunces displaySmall com rótulo em caixa-alta pequeno, como TURNO 2 / 4 / 40 do contador.
- Rodapé do diálogo: um único herói brass de largura total 'Aplicar N trocas'; Cancelar vira o X do cabeçalho e 'Compartilhar relatório' vira ícone — devolve ~100px de área útil no mobile.
- Gerador: mover _AiTrustPanel + AiUsageMeter para depois do formulário (ou colapsar em um chip de uma linha) para a primeira dobra ser escolha, não aviso (deck_generate_screen.dart:1030).
- Trocar o dropdown de Bracket (1136) por 5 tiles com numerais serifados 1-5 e o de Formato (1108) por tiles; trocar os dois SwitchListTile (1257/1270) por dois tiles de estado (fichário aceso/apagado).
- Pontos de partida (1950-1982) como grade 2 colunas de tiles de arquétipo com símbolos de mana das cores e nome em serifada ('Goblins', 'Controle UW').
- Prévia do deck gerado: arte do comandante como cabeçalho e as cartas em grade de miniaturas em vez de Text('1x nome') (1632-1658).
- Mão de exemplo: aumentar as cartas e mostrar as 7 de uma vez (leque ou 4+3) usando o espaço preto que hoje sobra; Keep/Mulligan lado a lado como dois tiles.
- Histórico: subir _HistoryCardRef de 34x48 para ~56x78 e transformar 'Testar mão inicial' / 'Abrir Battle' em dois tiles com ícone grande.
- Eliminar um nível de aninhamento: dentro do diálogo, seções sem borda (só título + espaçamento) para acabar com a caixa-dentro-de-caixa do DialogSectionCard.

### Redesenhos necessários

- Revisão da otimização fora do AlertDialog: superfície de tela cheia 'mesa de trocas' sobre fundo vivo, onde cada troca é um par de cartas com arte lado a lado (SAI escurecida/tingida de vermelho → ENTRA acesa em verde), toque para aprovar, cabeçalho com numerais grandes de antes/depois e um único herói dourado. 'Leitura da IA', referências meta e validação descem para uma camada secundária 'por quê' (uma página ao lado, não uma pilha de caixas antes das cartas).
- Gerador de Decks como prancha de composição em vez de formulário: arte do comandante como herói/fundo, tiles para formato, bracket (numeral), coleção e orçamento; o prompt como único campo de texto; CTA herói fixo. Estado de geração desenhado (a metáfora 'tecendo' já existe no texto) e resultado como galeria do deck com arte, curva e cores — não lista de texto.
- Folha de configuração da otimização (deck_optimize_sections.dart): substituir dropdown+switch+switch+slider+dropdown por tiles de intensidade, numerais de bracket e tiles de coleção/orçamento, tudo visível de uma vez.
- Família de estados desenhados para a área: carregando (esqueleto de cartas/tear em vez de CircularProgressIndicator), histórico vazio, deck vazio com slot tracejado de comandante (gramática do tile INICIATIVA 'sem dono'), e um estado de sucesso pós-aplicação com as cartas que entraram e numerais antes/depois no lugar da SnackBar.
- Mão de exemplo como mão de verdade: 7 cartas em leque sobre superfície de mesa, leitura (terrenos/curva) em numerais após a decisão, Keep/Mulligan como dois tiles grandes com cor e significado.
- Trocar o material-base da área: hoje quase tudo é surfaceSlate chapado + contorno de 1px com alfa; criar o equivalente aos tiles do contador (gradiente, profundidade, cor semântica por estado) como componente compartilhado e migrar DialogSectionCard/cartões da oficina para ele.

### Contestação do revisor

O auditor foi justo no essencial. Abri as 18 capturas e formei nota própria antes de reler a dele; meus vereditos por tela coincidem com os dele. Das 14 afirmações arquivo:linha que conferi no código, 12 batem (com desvios de 1–3 linhas). As 2 que não batem são a do 'Desfazer só no toast' e a dos '~55% de preto vazio' na mão de exemplo.

- **Conclusão que se sustenta:** a Oficina não está no nível do contador, e a distância é de gramática, não de acabamento.
  - O gerador é uma pilha de dropdowns, campos e switches, com disclaimer e barra de cota na primeira dobra. O deck gerado aparece como lista de texto '1x Nome', cortada em 18 linhas.
  - A revisão da otimização é um AlertDialog rolável, com caixas aninhadas, checkboxes, números-chave em texto de corpo e um rodapé de 3 ações que ocupa ~19% da altura.
  - Confirmei que a ausência de arte nas linhas de troca é do layout, não do fixture.
- **Onde ele foi duro demais (pouco):**
  - Pontuou a core_11 em cima de uma casca de teste que ele mesmo identificou.
  - Tratou como defeito o 'preto vazio' da mão de exemplo e do histórico. É artefato do harness, que captura o widget isolado.
  - Disse que 'Desfazer' vive só num toast. Há um botão persistente 'Desfazer aplicação' no histórico.
  - A nota global 3,5/10 é cerca de 1 ponto mais dura que a média da grade dele: 2,2/5, ou 4,4/10.
- **Onde foi generoso (pouco):** elogiou 'um único ✕' no leitor de carta. O leitor é a terceira camada, um modal sobre modal sobre página.
- **Principais pontos que ele perdeu** (lista completa no campo de problemas):
  - As duas gramáticas para a mesma decisão: trocas pareadas num payload, listas Remover/Adicionar em outro.
  - O desalinhamento vertical nas linhas de checkbox (crossAxisAlignment.start).
  - O título duplicado no gerador.
  - O inglês cru em destaque ('HIGH 88%').
  - Quatro superfícies-chave sem nenhuma captura: geração em andamento, resultado gerado, herói da Oficina e folha de configuração.

**Nota revisada:** 4,0 numa escala 0–10 (2,0/5 na rubrica), nível 'formulario'. As duas vitrines são formulário e modal. A periferia é 'correto-genérico': importação, histórico, mão de exemplo e deck vazio. Só o leitor de carta chega a 'bom abaixo do contador', por mérito da imagem da carta e não do chrome.

**Resposta à pergunta do dono:** não, o cuidado visual desta área não está no mesmo nível do contador.

**Discordâncias**

- **Nota global da área (3,5)** — auditor: notaArea 3.5, descrita no resumo como '3,5/10', com rubrica por critério em 0–5. · revisor: A escala ficou ambígua e o número não bate com a grade do próprio auditor. A média das notas por tela dele dá 2,21/5, ou seja, 4,4/10. Tirando a core_11, que é casca de teste, dá 4,6/10. O 3,5/10 é cerca de 1 ponto mais duro que a evidência dele. Dando peso maior às duas vitrines (gerador e revisão da otimização), chego a 4,0/10 (2,0/5). A projeção 'ganhos rápidos sobem para ~5,5' é um palpite sem base mostrada.
- **Otimização aplicada (core_11_optimization_applied.png)** — auditor: Notas 1 em quase tudo e a frase "'Desfazer' vive num toast que desaparece". · revisor: Duro demais em dois pontos. (1) Ele mesmo reconhece que o Scaffold preto com '2 mudanças aplicadas' é casca de teste. Conferi em core_product_acceptance_runtime_test.dart:433-448. Mesmo assim pontuou tipografia, material e primeira impressão em cima dela. O único elemento de produção na captura é a SnackBar. Essa tela deveria sair da média e ficar só como o achado 'não existe estado de sucesso desenhado'. (2) O desfazer não vive só no toast. Em produção há um botão persistente 'Desfazer aplicação' no evento do histórico (deck_workshop_tab.dart:581-600), visível na captura deck_workshop_06. O clímax continua sem desenho, mas a rede de segurança é durável.
- **Mão de exemplo (deck_workshop_08_sample_hand_continuity.png)** — auditor: '~55% da tela é preto vazio abaixo do cartão'. primeiraImpressao 2, estados 2. · revisor: O vazio preto é artefato do harness. A captura monta o SampleHandWidget sozinho dentro de Scaffold + SingleChildScrollView (deck_workshop_visual_runtime_proof_test.dart:826-842). Em produção ele fica embutido na Visão Geral (deck_details_overview_tab.dart:327, compact) e na aba Análise (deck_details_screen.dart:924), com conteúdo acima e abaixo. O 'espaço que sobra' não existe desse jeito. O problema real permanece e é de largura e gramática: o carrossel mostra 1 de 7 cartas a 74x104 com o lado esquerdo vazio, os nomes ficam truncados, há três caixas empilhadas e os botões Keep/Mulligan também empilhados. Subiria primeiraImpressao para 2,5–3. O veredito 'correto-generico' fica.
- **Histórico da oficina (06/07)** — auditor: 'Metade inferior da tela vazia e preta; nada de superfície viva'. · revisor: Parcialmente artefato. A captura é o DeckWorkshopTab isolado num Scaffold (teste :445-446), rolado até o fim do conteúdo, sem AppBar, sem abas e sem o herói acima. Fim de rolagem vazio não é defeito de design. As demais críticas conferem: miniatura 34x48, chips em coluna, TextButtons, CircularProgressIndicator. As notas 3 estão corretas.
- **Prévia de otimização no Android (core_09/core_10)** — auditor: 'sem mesa viva por trás (fundo preto)'. · revisor: O fundo preto é a casca do teste de aceitação. Em produção o diálogo abre sobre os Detalhes do Deck com scrim, como mostra optimization-card-reader-web/01_hover_card.png. Não muda o veredito 'formulario': caixas chapadas, _MetricDiffRow em texto de corpo, linhas de checkbox sem arte e rodapé com 3 ações empilhadas ocupando ~19% da altura são todos de produção. Essa frase, porém, deveria sair da lista.
- **Leitor de carta (05 / 02_full_reader)** — auditor: 'Um único ✕, sem ações concorrentes'. hierarquia 4, identidadeMtg 5. · revisor: Levemente generoso. O leitor é a TERCEIRA camada: página > AlertDialog de sugestões > leitor. No desktop (02_full_reader) vê-se modal sobre modal sobre página. No mobile (05), o título 'Sugestões para' vaza por trás da folha. Isso contraria o 'nada aninhado' da régua. O ✕ fecha só a camada de cima, e Cancelar/Compartilhar/Aplicar continuam por baixo. No desktop o texto oracle ainda é cortado na borda inferior da folha. Mantenho 'bom-abaixo-do-contador' e baixaria hierarquia para 3. A arte sintética sem moldura na captura 05 é do fixture; em produção é a imagem inteira da carta, como na 02.

**Problemas que o auditor perdeu**

- O leitor de carta é modal-sobre-modal: página > AlertDialog > folha do leitor. A melhor tela da área só existe como terceira camada empilhada. Ver 02_full_reader.png e o vazamento do cabeçalho 'Sugestões para' atrás da folha em deck_workshop_05_card_reader.png.
- O mesmo diálogo tem duas gramáticas para a mesma decisão. No pack web-mobile a revisão aparece como 'trocas pareadas' (TROCA 1, SAI → ENTRA). No Android (core_10) e no desktop (01_hover_card) aparece como duas listas separadas 'Remover'/'Adicionar' com checkbox por linha. O usuário aprende dois modelos mentais conforme o payload, e nenhum dos dois tem arte.
- Desalinhamento vertical nas linhas de checkbox. A Row usa crossAxisAlignment.start (deck_optimize_sheet_widgets.dart:2674-2676). Por isso o nome da carta fica colado no topo, enquanto o Checkbox compacto e o IconButton de 48dp (touchTargetMin, :2742-2748) ficam mais abaixo. Em core_10 'Cancel' e 'Plains x27' parecem linhas com uma segunda linha em branco. O auditor viu o 'espaço morto', mas não a causa nem o desalinhamento.
- Título duplicado no gerador: AppBar 'Gerador de Decks', logo abaixo H1 'Gerar Deck' e subtítulo. São dois títulos quase idênticos antes do disclaimer. O auditor elogiou o H1 em Fraunces sem notar a redundância, que empurra a primeira escolha ainda mais para baixo.
- Idioma misturado em rótulos de destaque: 'HIGH 88%' e 'HIGH 93%' em inglês, colados ao nome da carta em vermelho/verde, 'Preview seguro', 'Historic big spells' e 'Upgraded/Optimized' no dropdown de intenção (deck_optimize_sections.dart:191-200). O auditor chamou isso de 'jargão de máquina', mas não apontou que é texto em inglês cru numa UI pt-BR.
- O seletor de intensidade da folha de configuração é um Wrap de ChoiceChip (deck_optimize_sections.dart:~435-446). É sopa de chips, além dos dropdowns, switches e slider que ele listou. Os dropdowns ali são DropdownButton dentro de InputDecorator, não DropdownButtonFormField; o cheiro é o mesmo.
- A prévia do deck gerado mostra só 18 linhas de texto e depois '+ N linhas no deck principal' (deck_generate_screen.dart:1647-1665). Além de não ter arte, a proposta da IA é truncada numa lista parcial. O usuário não vê o deck que vai salvar.
- Prévia de importação: a faixa 'CARTAS RECONHECIDAS' corta a quarta carta na borda, sem indicação de rolagem horizontal, e o campo de texto acima aparece decapitado no topo. É o mesmo 'conteúdo cortado na borda' que ele criticou no modal.
- Não há nenhuma captura do estado de geração em andamento, do resultado gerado, do herói da Oficina nem da folha de configuração da otimização. Quatro das superfícies mais importantes da área foram julgadas só por código, porque o pacote de evidência visual não as cobre.

**Afirmações de código conferidas**

- ✅ deck_generate_screen.dart: DropdownButtonFormField em 1108 e 1136, TextField em 1204/1239/1284, SwitchListTile.adaptive em 1257/1270, CTA ElevatedButton.icon em 1306. — O grep bate linha a linha.
- ✅ deck_generate_screen.dart:1030 e 1084-1086: no mobile, _AiTrustPanel + AiUsageMeter são renderizados ANTES do formulário. — O ramo mobile chama _buildAiTrustSection() e só depois _buildGenerationForm (linhas ~1029-1037). _buildAiTrustSection monta _AiTrustPanel + AiUsageMeter(compact: true) em 1084-1086.
- ✅ deck_generate_screen.dart:1632/1647-1658: o deck gerado é exibido como Text '1x Nome' em caixa chapada com contorno hairline (1512-1520). — Linhas reais: 1633 ('1x $commanderName') e 1651 ('${qty}x ${name}'). O Container é surfaceSlate com Border strokeHairline (0,5px). A lista ainda é limitada por take(18), com rodapé '+ N linhas'.
- ✅ deck_generate_screen.dart:1950-1982: pontos de partida como linhas bodySmall cinza com ícone de 14px. — InkWell + Icon(north_east_rounded, size 14, textHint) + Text bodySmall textSecondary.
- ✅ deck_optimize_sheet_widgets.dart:684 AlertDialog com SizedBox(width:560)+SingleChildScrollView (716-718). Três ações em 1116-1136. — AlertDialog em 684, width 560 em 717, SingleChildScrollView em 718. TextButton Cancelar em 1117, TextButtons em 1119/1125 e ElevatedButton em 1130.
- ✅ _SelectableSuggestionLineItem (2692-2733) é só texto. A arte fica atrás de IconButton style_outlined de 20px (2748) ou de long-press. Checkbox em 2679 embora o InkWell já alterne (2656-2660). — Conferido no build: InkWell onTap alterna, onLongPress abre o leitor, Checkbox condicional a showCheckbox, coluna com nome/metadata/reason, e IconButton de 48dp com ícone de 20. Nenhum CardArtwork na linha. Não é artefato de fixture.
- ✅ deck_ui_components.dart:80-89: DialogSectionCard = surfaceSlate chapado + borda de 1px a 20% de alfa. — A cor e o alfa 0.2 conferem. A largura é AppTheme.strokeMedium = 0,8px (app_theme.dart:208), não 1px exato. O efeito visual é o mesmo.
- ✅ deck_workshop_tab.dart:696-698: miniaturas do histórico a 34x48. Gradiente do herói com brass a 4,5% de alfa. Carregando = CircularProgressIndicator (871). — SizedBox 34x48 com CardArtwork + fallback ScryfallImageHelper.namedImageUrl, então a arte é real em produção. brass400 com alpha 0.045 está na linha 250. CircularProgressIndicator em 871.
- ✅ sample_hand_widget.dart:238-239: cartas a 74x104 no modo compacto. Caixa chapada (257). Mulligan/Keep empilhados (542-566). — imageWidth 74 e imageHeight 104 quando compact. stackActions = maxWidth < 520. OutlinedButton Mulligan + FilledButton Keep.
- ✅ deck_optimize_dialogs.dart:232: o sucesso da otimização é apenas SnackBar com 'Desfazer'. — showOptimizeSuccessSnackBar está em 230-240.
- ✅ A tela preta da core_11 é casca do teste (core_product_acceptance_runtime_test.dart:435-445), não produção. — O Scaffold com AppBar 'Otimização · revisão segura', Text(status) e FilledButton 'Revisar otimização' está dentro do teste de integração.
- ❌ 'Desfazer', ação de segurança importante, vive num toast que desaparece. — Incompleto. Existe um desfazer persistente no histórico: OutlinedButton 'Desfazer aplicação', condicionado a event.canRollback, em deck_workshop_tab.dart:581-600. Aparece na captura deck_workshop_06.
- ✅ deck_optimize_sections.dart:42-64 Dropdown de bracket, SwitchListTile 82/137/148, Slider 168, Dropdown 'Intenção do rebuild' 181-207. — Confere. Os dropdowns são DropdownButton dentro de InputDecorator (46-47 e 185-186). Há ainda um seletor de intensidade em ChoiceChips que ele não citou.
- ❌ '~55% da tela é preto vazio' na mão de exemplo, tratado como defeito do design. — É artefato do harness. O widget é montado sozinho em Scaffold+SingleChildScrollView (deck_workshop_visual_runtime_proof_test.dart:826-842). Em produção fica embutido em abas com mais conteúdo (deck_details_overview_tab.dart:327 e deck_details_screen.dart:924).

## Cartas e catálogo: detalhe da carta, busca, coleções/sets, impressões

**Auditor 4.5 → revisor 5** · correto, genérico · auditor foi *justo*

Resposta direta: não. Esta área está a cerca de meia distância do contador (4,5/10) — nível 'correto, genérico', com duas telas que caem em formulário (detalhe do set/Última edição e Fichário vazio).

Por quê: o contador foi composto como objetos (azulejos, miniaturas, numerais serifados, estado dentro do objeto, um herói). Cartas e catálogo foram montados com o kit Material bem tematizado: ListTile, Wrap de chips, tabela chave-valor, ChoiceChip, DropdownButton, Dialog e bottom sheet com rádio. Tudo funciona e é limpo, mas é lista de texto com selo de imagem. Ironia: é a área com mais matéria-prima visual do app (arte de carta, símbolos de set, mana, raridade, foil) e a arte aparece a 46-58px de largura em quase tudo, exceto no detalhe da carta.

Evidências de que o cuidado não é o mesmo: (1) o campo de busca tem um defeito visível de pílula dupla que foi aprovado como golden e aparece nas capturas ao vivo; (2) o commit e6737c53b 'UX audit packs' piorou o catálogo de sets — trocou art_crop + selo + símbolo SVG por carta inteira espremida numa caixa paisagem 84x56 — e as capturas de sets_catalog ainda mostram a versão antiga; (3) o símbolo do set existe nos dados e no cache e nenhuma tela o desenha; os variants setArt e artCrop do CardArtwork não são usados em lugar nenhum do app; (4) Fraunces aparece em só 4 pontos da área (nome da carta no detalhe, título 'Coleção', títulos de dois modais) e não há um único numeral expressivo.

O que está bom e é fundação real: CardArtwork com estados e badge dentro do objeto, verso BrewTact pintado à mão para arte ausente, AppStatePanel novo (eyebrow + serifada + motivo), símbolos de mana reais no texto de regras, tokens de cor/raridade. Em produção as miniaturas mostram arte real do Scryfall (o anel repetido é fixture) — o problema não é o fixture, é o layout não dar palco à arte. A distância é de composição, não de infraestrutura: os ganhos rápidos listados fecham ~1,5 ponto; chegar ao nível do contador exige redesenhar set, catálogo, busca e seletor de impressão como galerias/azulejos.

Registro: das 22 capturas vistas, 7 do pacote ux-pack-01-catalog-web pertencem a outras áreas (community_public_decks, community_tab_1-3, deck_generate_empty, deck_import_detected, post_game_empty) e não entraram na nota; de passagem, gerador de decks, importar lista e pós-jogo são formulários empilhados puros (dropdowns, campos de texto, chips, botão largo) e estão abaixo desta área. Todos os caminhos listados existiam. Referência usada: /private/tmp/claude-501/-Users-desenvolvimentomobile-Documents-rafa-mtg-mtgia/c6c20cac-53ba-46a9-bda2-85f860cc4f8f/scratchpad/ref/contador_hub_referencia.png.

- **Melhor tela:** Detalhe da carta (mobile) — única tela em que a arte é o herói em largura total; empatada em linguagem com o estado inicial da busca (eyebrow + Fraunces + motivo), que é a única que fala a tipografia do contador.
- **Pior tela:** Detalhe do set / Última edição — sopa de chips no cabeçalho + lista de ListTile com miniaturas de 46px e metadados redundantes; a vitrine da edição nova não tem arte-chave, símbolo do set nem numeral.

### Notas por tela

| Tela | Obj | Hier | Tipo | Mat | MTG | Resp | Est | 1ªimp | Média | Veredito |
|---|---|---|---|---|---|---|---|---|---|---|
| Detalhe da carta (mobile 390) | 3 | 3 | 3 | 2 | 4 | 4 | 4 | 3 | 3.2 | correto, genérico |
| Detalhe da carta (desktop) + fallback sem arte | 3 | 3 | 3 | 2 | 4 | 3 | 4 | 3 | 3.1 | correto, genérico |
| Detalhe da carta — erro de carregamento | 3 | 4 | 2 | 3 | 3 | 4 | 4 | 3 | 3.2 | bom, abaixo do contador |
| Busca de cartas — resultados | 2 | 3 | 2 | 3 | 3 | 2 | 3 | 2 | 2.5 | correto, genérico |
| Busca de cartas — estado inicial/vazio | 3 | 4 | 4 | 3 | 3 | 4 | 4 | 3 | 3.5 | bom, abaixo do contador |
| Seletor de impressão (bottom sheet) | 2 | 4 | 3 | 2 | 3 | 3 | 4 | 3 | 3.0 | correto, genérico |
| Catálogo de coleções (aba Edições e rota /sets) | 3 | 3 | 2 | 2 | 2 | 3 | 3 | 3 | 2.6 | correto, genérico |
| Detalhe do set / Última edição | 2 | 2 | 2 | 2 | 2 | 3 | 3 | 2 | 2.2 | formulário |
| Coleção > Fichário vazio | 2 | 3 | 2 | 2 | 2 | 3 | 3 | 2 | 2.4 | formulário |
| Prévia de carta no deck (modal, desktop) | 3 | 3 | 3 | 2 | 4 | 3 | 3 | 3 | 3.0 | correto, genérico |

#### Detalhe da carta (mobile 390)

Captura: `docs/qa/ui-live/current/ux-pack-01-catalog-web/card_detail_success.png`

**Problemas**

- Abaixo da carta a tela vira página de configurações: rótulo azul pequeno 'Texto de Regras' + caixa chapada com contorno 1px (card_detail_screen.dart:447-464) e 'Detalhes' como tabela chave-valor com ícone cinza à esquerda, valor à direita e Divider entre linhas (card_detail_screen.dart:482-591, 624-673).
- Nenhum numeral expressivo: CMC, raridade, código e data são texto bodyMedium de tabela. No contador '2', '4', '40' são objetos; aqui 'CMC 1' é uma célula.
- Zero ações na tela: não há adicionar ao deck/fichário, ver outras impressões, preço ou legalidade. A tela mostra a carta e acaba; não existe herói de ação.
- A carta é colada no topo sem palco: fundo backgroundAbyss chapado, sem brilho ambiente/art_crop desfocado, cantos superiores retos e inferiores arredondados (card_detail_screen.dart:301-306). O variant artCrop existe em card_artwork.dart:94 e não é usado por nenhuma tela do app.
- Nome da carta duplicado (AppBar em Inter bold + headline serifado logo abaixo) — card_detail_screen.dart:159-167 e 405-411.
- Raridade é um ponto de 10px + texto; cor com significado existe (AppTheme.rarityColor) mas não vira material.

**Acertos**

- A arte é protagonista de verdade: carta inteira em largura total, toque amplia em InteractiveViewer. Em produção é imagem real Scryfall via CardArtwork/CachedCardImage (fixture usa a mesma arte do anel para todas as cartas).
- Nome em Fraunces (headlineSmall) com custo de mana em símbolos reais à direita.
- Texto de regras renderiza símbolos de mana/tap inline (OracleTextWidget) e identidade de cor usa pips reais.
- Respiro correto, sem parede de texto.

#### Detalhe da carta (desktop) + fallback sem arte

Captura: `docs/qa/ui-live/current/card-details-navigation-web/02_full_details_without_modal.png ; docs/qa/ui-live/current/card-back-fallback-web/01_missing_art_uses_manaloom_card_back.png`

**Problemas**

- A coluna direita é uma tabela de 600px com rótulo colado à esquerda e valor solto no meio da caixa — leitura de painel administrativo (card_detail_screen.dart:496-588).
- Metade inferior direita da tela fica vazia; nada ocupa o espaço com impressões, preço, legalidade ou cartas relacionadas.
- Quando a URL da imagem é nula, a tela NÃO usa o verso BrewTact desenhado: cai numa caixa cinza com Icons.style + 'Sem imagem' (card_detail_screen.dart:322-353). O verso bonito só aparece quando a URL existe e falha.
- Mesma gramática chapada do mobile: surfaceElevated + borda outlineMuted 0.4, sem gradiente nem profundidade.

**Acertos**

- Layout de duas colunas com a carta grande à esquerda é a decisão certa.
- O verso de carta BrewTact pintado em CustomPainter (cached_card_image.dart:421-600) é um estado de falha desenhado, com identidade própria — nível alto para um fallback.
- Badge de estado da arte (referência, offline, baixa resolução) mora dentro do objeto (card_artwork.dart:321-369).

#### Detalhe da carta — erro de carregamento

Captura: `docs/qa/ui-live/current/ux-pack-01-catalog-web/card_detail_error.png`

**Problemas**

- Nesta captura (03/08) o título está em Inter bold dentro de uma caixa com contorno; o AppStatePanel mais novo (golden de 09/09) já usa eyebrow + Fraunces — a captura está defasada.
- Botão 'Tentar novamente' é botão largo padrão, não um objeto.

**Acertos**

- Estado desenhado: motivo de órbita + cartas-fantasma ao fundo, glifo próprio de carta, cor de alerta com significado, uma única ação.
- Carregando também é AppStatePanel.loading com cópia específica (card_detail_screen.dart:119-123), não spinner solto.

#### Busca de cartas — resultados

Captura: `app/test/ui/goldens/runtime/web_mobile/card_search_results.png`

**Problemas**

- DEFEITO VISUAL abençoado como golden: o campo de busca aparece como pílula dupla — um campo de ~26px com contorno dourado preso no topo de um contêiner-pílula de 48px, sobrando um 'lábio' vazio embaixo. Causa: o TextField só define border: InputBorder.none (card_search_screen.dart:365-376) e herda filled + focusedBorder do tema (app_theme.dart:717-731). O mesmo defeito aparece ao fundo das capturas ao vivo do seletor de impressão. É o controle mais usado da área.
- Sopa de chips dentro de cada linha: código do set, 'N impressões', 'arte de referência', pips de identidade, custo de mana, Possui/Livre/Em troca e aviso — até 7 tipos num Wrap com spacing 5/3 e fonte 10-11px (card_search_screen.dart:918-948; classes 1022-1220).
- Miniatura de 54x74px (card_search_screen.dart:877-878): a arte é um selo, o texto é o protagonista. Resultado de busca de carta deveria ser galeria.
- Zero serifada: nome em bodySmall w900 Inter, cabeçalho 'Resultados para' em Inter w900 (card_search_screen.dart:764-771, 890-901).
- Com 1 resultado, 70% da tela é vazio preto; o modo 'spotlight' (carta 126x176) só existe em desktop (card_search_screen.dart:620-637).
- Adicionar abre um Dialog modal clássico: linha 'Quantidade' + stepper + radio-rows de comandante + botões largos Cancelar/Adicionar (card_search_screen.dart:1284-1500, 1635-1677). Sem captura, mas o código é formulário em modal.

**Acertos**

- Tile tem gradiente sutil + sombra e borda dourada quando pode adicionar (card_search_screen.dart:840-862) — há intenção de material.
- Botão circular dourado de adicionar é claro e muda de ícone quando exige escolher impressão.
- Disponibilidade da coleção (Possui/Livre/Em troca) com cor semântica é informação útil — só está mal embalada.

#### Busca de cartas — estado inicial/vazio

Captura: `app/test/ui/goldens/runtime/web_mobile/card_search_empty.png`

**Problemas**

- Mesmo defeito da pílula dupla no campo de busca.
- Oportunidade perdida: o estado inicial de uma busca de cartas é uma instrução ('Digite pelo menos 3 letras'). Deveria ser superfície de descoberta com objetos: última edição com arte, buscas recentes como miniaturas, azulejos por cor/tipo.
- Regra técnica ('3 letras') como mensagem principal é voz de formulário.

**Acertos**

- Eyebrow dourado em caixa alta + título em Fraunces + motivo de órbita com cartas-fantasma: é a única tela da área que fala a mesma língua tipográfica do contador.
- Composição centrada, calma, um ponto focal.

#### Seletor de impressão (bottom sheet)

Captura: `docs/qa/ui-live/current/ux-pack-01-card-printing-web/card_search_printing_picker.png ; .../card_search_printing_selected.png`

**Problemas**

- A escolha mais visual do app (qual ARTE/edição eu quero) foi resolvida como lista de rádio em modal: showModalBottomSheet (card_printing_picker.dart:30), ListView de linhas (423-434), miniatura 58x82 (493-494), ícone radio_button (≈600) e botão de confirmação no rodapé (371-378).
- Frase instrutiva de formulário no cabeçalho: 'confirme set, número e acabamento antes de adicionar' (card_printing_picker.dart:299).
- Dois toques obrigatórios (selecionar + 'Usar esta impressão') para algo que poderia ser um toque na carta.
- Foil vs non-foil é um chip azul de texto; não há tratamento visual de foil (brilho/gradiente) na miniatura.
- Metade da folha fica vazia com 2 opções; rodapé 'Escolha uma opção.' + botão desabilitado cinza é puro formulário.

**Acertos**

- Estado selecionado mora no objeto: borda dourada + check dourado no tile.
- Preço em dourado com hierarquia própria; título em Fraunces.
- Carregando/erro/vazio do seletor usam AppStatePanel com cópia específica (card_printing_picker.dart:390-420).

#### Catálogo de coleções (aba Edições e rota /sets)

Captura: `docs/qa/ui-live/current/ux-pack-01-catalog-web/sets_catalog.png ; .../sets_catalog_route.png`

**Problemas**

- CAPTURA DEFASADA E O CÓDIGO ATUAL É PIOR: a captura (03/08) mostra art_crop 84x56 com selo do código sobre a arte. O commit e6737c53b (10/08) trocou para carta inteira 'normal' com CardArtworkVariant.fullCard/BoxFit.contain dentro da mesma caixa paisagem 84x56 (sets_catalog_screen.dart:594-623) — em produção vira uma mini-carta de ~40x56 com barras cinza laterais — e removeu o selo de código e o símbolo SVG do set.
- Símbolo do set (a identidade MTG mais forte de uma edição) virou código morto: iconSvgUri existe no modelo (mtg_set.dart:12) e SetIconSvgCache existe (set_icon_svg_cache.dart), mas nenhuma tela renderiza. O variant setArt (card_artwork.dart:99) também não é usado por ninguém.
- Tile é ListTile isThreeLine com Wrap de 4 metadados ícone+texto de 12px + pílula de status (sets_catalog_screen.dart:540-582): linha rotulada, não objeto.
- Cabeçalho é caixa-dentro-de-caixa: card com título + subtítulo descritivo + TextField (sets_catalog_screen.dart:375-411); título em Inter, não serifada.
- Filtros são ChoiceChip padrão (sets_catalog_screen.dart:508); no código atual viraram Wrap de 2 linhas no mobile.
- Na aba Edições são 4 níveis de navegação empilhados antes do conteúdo: bottom nav, abas da Coleção (fontXs, collection_screen.dart:240-260), cabeçalho, chips.
- Erro e vazio usam ícones Material genéricos (Icons.error_outline_rounded / search_off_rounded, sets_catalog_screen.dart:266, 278).

**Acertos**

- Na captura, a arte recortada com selo dourado do código é o embrião certo de um azulejo de edição.
- Pílula de status com cor semântica (Nova verde, Antiga cinza).

#### Detalhe do set / Última edição

Captura: `docs/qa/ui-live/current/ux-pack-01-catalog-web/set_detail_tst.png ; .../latest_set.png`

**Problemas**

- Cabeçalho abre com sopa de 4 chips (código, status, data, '5/5 cartas') ANTES do nome do set (set_cards_screen.dart:366-388); o nome vem depois em Inter 18px w700 (390-396). Sem arte-chave, sem símbolo do set, sem numeral.
- Lista de ListTile com miniatura de 64px de altura (~46px de largura) (set_cards_screen.dart:430-454). A página de um set é O lugar para galeria de cartas (página de fichário 3 colunas) e é uma lista de texto.
- Cada linha repete 'S3-07 Visual Fixture Set • 2026 • Common' — informação redundante dentro da tela do próprio set (set_cards_screen.dart:475-483). Custo de mana e cor de raridade, que seriam visuais, não aparecem.
- Até o 'grid' de desktop (>=960px) é grade de linhas com mainAxisExtent 92 (set_cards_screen.dart:299-315), não de cartas.
- Material: surfaceSlate chapado + borda hairline em tudo.
- 'Última Edição' é literalmente a mesma tela com outro título (latest_set_collection_screen.dart, 15 linhas): a vitrine da edição nova não tem tratamento de destaque nenhum.

**Acertos**

- Miniaturas usam CardArtwork com fallback e badge de referência; em produção mostram a arte real da impressão.
- Pílulas de código/foil têm cor consistente com a busca.

#### Coleção > Fichário vazio

Captura: `docs/qa/ui-live/current/ux-pack-01-catalog-web/collection_empty.png`

**Problemas**

- Campo de busca + três dropdowns 'Condição: todas ▾ / Raridade: todas ▾ / Idioma: todas ▾' (DropdownButton, binder_screen.dart:1582-1608, 1815-1862) exibidos sobre uma coleção VAZIA: é barra de filtros de planilha.
- Três níveis de abas de texto (bottom nav, Fichário/Ofertas/Trocas/Edições, Tenho/Quero) antes de qualquer conteúdo.
- Estado vazio é caixa cinza com glifo de livro 48px, título Inter e botão largo (binder_screen.dart:590-640) — não usa o AppStatePanel com eyebrow/serifada/motivo que a busca já tem.
- Nenhuma arte de carta, nenhum numeral (valor da coleção, contagem) — a tela 'minha coleção' não tem nada colecionável à vista.

**Acertos**

- Uma ação primária clara ('Buscar carta') em dourado.
- Título 'Coleção' da AppBar em Fraunces (collection_screen.dart:220-225).

#### Prévia de carta no deck (modal, desktop)

Captura: `docs/qa/ui-live/current/card-details-navigation-web/01_deck_card_preview_modal.png (03_back_to_deck é a tela de deck por trás, fora desta área)`

**Problemas**

- É um Dialog central (decks/widgets/deck_details_dialogs.dart:354-405) — exatamente o padrão 'modal' que o dono rejeita — com 4 botões de texto/contorno de pesos parecidos: 'Trocar edição', 'Explicar com IA', 'Ver Detalhes', 'Fechar'. Sem herói.
- Bloco de edição é caixa com contorno e linha de metadados separados por '•'.
- Dois caminhos para fechar/avançar competindo no rodapé.

**Acertos**

- Arte da carta grande à esquerda, nome em Fraunces, símbolos de mana reais no texto.
- Navegação para detalhe completo fecha o modal corretamente (sem modal empilhado).

### Cheiros de formulário (arquivo:linha)

- `app/lib/features/cards/screens/card_search_screen.dart:365` — Campo de busca com pílula dupla: InputDecoration só zera `border`; herda filled + enabledBorder/focusedBorder do tema (app_theme.dart:717-731). Defeito visível no golden card_search_results.png/card_search_empty.png e ao fundo das capturas ao vivo do seletor.
- `app/lib/features/cards/screens/card_detail_screen.dart:482` — _buildDetailsGrid: tabela chave-valor estilo configurações (ícone cinza + rótulo à esquerda, valor à direita, Divider entre linhas, caixa chapada com borda 1px). Linhas 496-507 (caixa) e 624-673 (_adaptiveDetailRow).
- `app/lib/features/cards/screens/card_detail_screen.dart:447` — Rótulo de seção azul pequeno + caixa chapada com contorno para o texto de regras (447-464); sem serifada, sem material.
- `app/lib/features/cards/screens/card_detail_screen.dart:322` — Sem URL de imagem cai numa caixa cinza com Icons.style + 'Sem imagem' em vez do verso BrewTact desenhado que o CardArtwork já entrega.
- `app/lib/features/cards/screens/card_search_screen.dart:918` — Sopa de chips por resultado: Wrap com até 7 tipos de pílula (set, impressões, arte de referência, identidade, mana, Possui/Livre/Em troca, aviso) em fonte 10-11px; classes de pílula em 1022-1220.
- `app/lib/features/cards/screens/card_search_screen.dart:877` — Miniatura de resultado 54x74px: lista de texto com selo, não galeria. Modo spotlight 126x176 só em desktop (620-637).
- `app/lib/features/cards/screens/card_search_screen.dart:1284` — _AddCardDialog: Dialog modal com linha 'Quantidade' + stepper, radio-rows de comandante (_CommanderChoiceCard 1635-1677) e par de botões largos Cancelar/Adicionar (1440-1495).
- `app/lib/features/cards/widgets/card_printing_picker.dart:423` — Escolha de impressão como lista de rádio em bottom sheet modal (showModalBottomSheet na linha 30): miniatura 58x82 (493-494), ícone radio (≈600), frase instrutiva (299), botão de confirmação no rodapé (371-378).
- `app/lib/features/collection/screens/sets_catalog_screen.dart:540` — Tile de set é ListTile isThreeLine com Wrap de 4 _MiniMeta ícone+texto + pílula de status; chevron à direita. Linha rotulada, não azulejo.
- `app/lib/features/collection/screens/sets_catalog_screen.dart:605` — Arte do set: carta inteira (fullCard, BoxFit.contain) numa caixa paisagem 84x56 → mini-carta com barras laterais em produção. Regressão do commit e6737c53b, que também removeu o selo de código e o símbolo SVG; variant setArt (card_artwork.dart:99) sem nenhum uso.
- `app/lib/features/collection/screens/sets_catalog_screen.dart:375` — Cabeçalho caixa-dentro-de-caixa com título Inter + subtítulo descritivo + TextField (404-411) e fileira de ChoiceChip (508); estados de erro/vazio com ícones Material genéricos (266, 278).
- `app/lib/features/collection/screens/set_cards_screen.dart:366` — Cabeçalho do set abre com 4 _InfoChip antes do nome; nome em Inter 18px (390-396); sem arte-chave, símbolo ou numeral.
- `app/lib/features/collection/screens/set_cards_screen.dart:430` — Cartas do set como ListTile com miniatura de 64px de altura e metadados de edição redundantes por linha (475-483); 'grid' de desktop é grade de linhas de 92px (299-315).
- `app/lib/features/collection/set_icon_svg_cache.dart:7` — Símbolo do set existe nos dados (mtg_set.dart:12 iconSvgUri) e no cache, mas nenhuma tela o renderiza — identidade MTG disponível e descartada.
- `app/lib/features/binder/screens/binder_screen.dart:1582` — Quatro _FilterDropdown (DropdownButton, 1815-1862) 'Condição/Raridade/Idioma/Ordenar: todas' visíveis mesmo com a coleção vazia; estado vazio em caixa genérica (590-640) sem AppStatePanel.
- `app/lib/features/collection/screens/collection_screen.dart:240` — TabBar de 4 abas de texto em fontXs + abas Tenho/Quero aninhadas: três níveis de navegação textual antes do conteúdo.
- `app/lib/features/decks/widgets/deck_details_dialogs.dart:354` — Prévia de carta como Dialog central com 4 botões de texto/contorno de peso parecido (Trocar edição, Explicar com IA, Ver Detalhes, Fechar).

### Ganhos rápidos

- Corrigir a pílula dupla do campo de busca: enabledBorder/focusedBorder: InputBorder.none e filled: false em card_search_screen.dart:365-376; regenerar os goldens card_search_*.png (hoje o defeito está abençoado como referência).
- Reverter a regressão da arte de set: voltar a art_crop + CardArtworkVariant.setArt (cover 3:2) com selo do código sobre a arte em sets_catalog_screen.dart:594-623, e recapturar sets_catalog*.png (capturas atuais não refletem o código).
- Religar o símbolo SVG do set (mtg_set.iconSvgUri + SetIconSvgCache) no tile do catálogo e no cabeçalho do set.
- card_detail_screen.dart:322-353: trocar a caixa cinza 'Sem imagem' por CardArtwork(imageUrl: null), que já pinta o verso BrewTact.
- Fraunces onde hoje é Inter pesado: nome do set (set_cards_screen.dart:390), 'Catálogo de Coleções', nome da carta nos resultados e 'Resultados para'. Numerais serifados grandes para '5/5 cartas', CMC e contagem de resultados.
- Dentro da tela do set, suprimir nome/ano do set em cada linha (set_cards_screen.dart:475-483) e mostrar custo de mana + cor de raridade no lugar.
- Busca: fundir Possui/Livre/Em troca num único objeto de disponibilidade e limitar a 3 pílulas por linha; subir a miniatura de 54x74 para ~72x100.
- Esconder busca + dropdowns do fichário enquanto a coleção está vazia e usar AppStatePanel (eyebrow + Fraunces + motivo) no lugar da caixa genérica.
- Detalhe da carta: fundo com art_crop desfocado/gradiente atrás da carta (variant artCrop já existe) e remover o nome duplicado da AppBar.
- Seletor de impressão: toque único na carta confirma (remover rádio + botão de rodapé) e miniatura maior; tratamento de brilho para foil.

### Redesenhos necessários

- Detalhe do set / Última edição como vitrine: herói com arte-chave (art_crop) + símbolo do set + nome em Fraunces + numeral grande de cartas/raridades; corpo em galeria de cartas inteiras (3 colunas no mobile, página de fichário) com alternância para lista.
- Catálogo de coleções como grade de azulejos de edição: arte 3:2 em cover, símbolo do set, código como selo, status como cor do azulejo (futura tracejada, nova com brilho) — mesma gramática do hub do contador; filtros como azulejos/segmento visual, não ChoiceChip.
- Detalhe da carta: substituir a tabela 'Detalhes' por azulejos de fato (raridade com cor/material, set com símbolo e arte, CMC como numeral serifado, identidade como pips grandes), faixa horizontal de outras impressões com miniaturas, preço e uma ação heroína (adicionar ao deck/fichário).
- Resultados de busca como galeria de cartas (grade 2-3 colunas com carta inteira, estado de posse como selo sobre a carta) com lista densa opcional; estado inicial como superfície de descoberta (última edição, buscas recentes em miniatura, azulejos por cor/tipo).
- Escolha de impressão como carrossel/leque de cartas grandes lado a lado (arte é a decisão), foil com tratamento visual, preço como numeral — sem modal de rádio.
- Fluxo de adicionar carta sem Dialog: quantidade e 'definir como comandante' como objetos sobre a própria carta (stepper numeral serifado, coroa), no padrão do tile COROA do contador.
- Fichário: cabeçalho com numerais (valor, total, Tenho/Quero como azulejos com contagem) e grade de cartas; filtros como objetos visuais (pips de cor, gemas de raridade) em vez de dropdowns; achatar os 3 níveis de abas.

### Contestação do revisor

O auditor foi justo. Não, esta área não está no nível do contador. Minha nota revisada é 5,0/10 (a dele é 4,5), no mesmo nível "correto, genérico".

Abri a referência do contador e 18 imagens da área. Foram as 14 capturas listadas (só não abri 03_back_to_deck, que é tela de deck, nem as 7 de outras áreas) e 4 goldens de 09/09. Formei minhas notas antes de reler as dele. Conferi 8 afirmações arquivo:linha e todas batem, incluindo:

- **Campo de busca:** a pílula dupla aparece no golden e ao fundo das capturas do seletor de impressão.
- **Catálogo de sets:** a regressão do commit e6737c53b é real, e o golden atual de sets_catalog a confirma visualmente.
- **Código morto:** o símbolo de set e os variants setArt e artCrop não são usados por nenhuma tela.
- **Detalhe da carta:** a tela não tem nenhuma ação.
- **Tipografia:** a Fraunces aparece em só uns 4 pontos da área.

Minhas discordâncias são de calibragem; o veredito não muda:

- **Nota da área:** o 4,5 é um pouco mais severo do que as notas por tela dele sustentam. A média dele é 2,89/5, o que dá 5,8 em escala proporcional. A minha é 2,8/5. Fecho em 5,0.
- **Tela de erro do detalhe:** ele foi duro por pontuar a captura de 03/08. O golden atual já tem eyebrow e Fraunces.
- **Seletor de impressão:** ele foi levemente duro. A confirmação explícita é decisão de produto legítima, porque foil e non-foil têm preços diferentes. O que pesa contra a tela é a miniatura de 58px, o rádio e o rodapé.
- **Catálogo de sets:** aqui ele foi generoso. Pontuou a captura antiga, que mostra art_crop com selo dourado. O golden atual mostra uma mini-carta solta num quadro vazio. No estado real a tela vale cerca de 2,4, não 2,6.
- **Fichário vazio:** o acerto "uma ação primária clara" não vale mais. O golden de 09/09 tem dois botões largos e a dica "Deslize ou avance para ver os outros filtros.".
- **Detalhe da carta (mobile):** a ilustração sem moldura do fixture favorece a tela. Em produção entra a carta inteira com moldura, encostada nas bordas e com cantos superiores retos.

Ele não puniu artefato de fixture em nenhuma tela. O anel repetido foi identificado como fixture, e em produção a arte real vem do Scryfall via CardArtwork. Nenhuma tela desta área é caso em que formulário seja a forma certa, como login ou texto legal.

O que ele perdeu de mais relevante:

- **Eyebrow errado no erro:** a tela "Carta indisponível" mostra "PRÓXIMO PASSO". card_detail_screen.dart:124 não passa `status`, e app_state_panel.dart:61-68 cai no padrão. Os "estados desenhados" são hoje um molde único reaplicado.
- **Redundância no detalhe:** a tela repete três vezes o que a carta inteira já mostra (AppBar, imagem, headline com caixa de regras). Os dados que a carta não mostra ficam na tabela.
- **Azul frost sem significado:** rótulos, pílulas e ícones usam a mesma cor. No contador, cor tem significado.
- **Goldens novos ignorados:** os goldens de 09/09 mostram o estado atual e não entraram na pontuação dele.

A melhor e a pior tela dele se mantêm: detalhe da carta no mobile e detalhe do set / Última edição. A distância para o contador é de composição. A infraestrutura já existe (CardArtwork, verso pintado, AppStatePanel, símbolos de mana). As telas foram montadas com ListTile, Wrap de chips, tabela chave-valor, DropdownButton e Dialog, e a arte aparece com 40 a 58px em quase tudo.

**Discordâncias**

- **Nota da área (4,5/10)** — auditor: notaArea 4,5 com nível 'correto-generico'. · revisor: A média das notas por tela do próprio auditor é 2,89/5. Em escala proporcional isso dá 5,8/10. Só vira cerca de 4,7 se o 1 for mapeado para zero. O 4,5 publicado está uns 0,5 a 1 ponto abaixo do que as notas dele sustentam. Minhas notas, feitas antes de reler as dele, dão média de 2,8/5. O estado atual do código é pior que as capturas de 03/08 em duas telas: catálogo de sets e fichário vazio. Fecho em 5,0/10: metade do caminho até o contador, mesmo nível 'correto-generico'. É ajuste de calibragem; o veredito não muda.
- **Detalhe da carta — erro de carregamento** — auditor: tipografia 2, material 3, veredito 'bom-abaixo-do-contador', com base na captura de 03/08. Ele mesmo reconhece que a captura está defasada. · revisor: Ele foi duro por usar captura velha. O golden atual (app/test/ui/goldens/runtime/web_mobile/card_detail_error.png, 09/09) já mostra eyebrow dourado, título em Fraunces, motivo de órbita e a caixa com contorno removida. Tipografia hoje é 4, não 2. Em contrapartida o golden revela um defeito que ele não viu: o eyebrow diz 'PRÓXIMO PASSO' em cima de 'Carta indisponível' (detalhe em problemas perdidos). No saldo a tela fica em 3,4 a 3,5, e o veredito dele se mantém.
- **Seletor de impressão (bottom sheet)** — auditor: objetosVisuais 2. Trata como defeito os 'dois toques obrigatórios (selecionar + Usar esta impressão)' e propõe confirmar com um toque. · revisor: Ele foi um pouco duro. A confirmação explícita é decisão de produto documentada no código (card_printing_picker.dart:20-22: 'The picker never guesses... only after the user explicitly confirms'). Foil e non-foil têm preços diferentes e alimentam o fichário, então errar aqui custa caro. Para este caso, uma folha com confirmação é forma legítima. O que merece punição é a embalagem: miniatura de 58x82, rádio, rodapé 'Escolha uma opção.' e foil sem tratamento visual. O tile selecionado, com borda e check dourados, é um dos poucos pontos da área em que o estado mora no objeto. Eu daria objetosVisuais 3. A média da tela sobe de 3,0 para cerca de 3,1 e o veredito não muda.
- **Catálogo de coleções** — auditor: Média de 2,6, pontuada sobre a captura de 03/08. A regressão entra só como observação de código. · revisor: Aqui ele foi generoso na nota. O golden atual (app/test/ui/goldens/runtime/web_mobile/sets_catalog.png, 09/09) confirma o que ele deduziu do código. A arte virou uma mini-carta de cerca de 40x56 solta num quadro vazio de 84px. O selo dourado do código virou um meta '# TST'. Os chips quebram em 2 linhas, com 'Antigas' órfã. Pontuando o que o usuário veria hoje: objetosVisuais 2, identidadeMtg 2, primeiraImpressao 2, média de cerca de 2,4. A tela deveria ser pontuada pelo estado atual, não pela captura que a favorece.
- **Coleção > Fichário vazio** — auditor: Acerto listado: 'Uma ação primária clara (Buscar carta) em dourado'. Veredito 'formulario'. · revisor: O acerto está desatualizado. No golden de 09/09 (collection_empty.png) são dois botões largos empilhados: 'Importar lista' dourado e 'Buscar carta' com contorno. Apareceu também a linha de instrução 'Deslize ou avance para ver os outros filtros.', com ícone de mão e botão de seta. Uma barra de filtros que precisa de manual, sobre uma coleção vazia, reforça o veredito dele. Ressalva de escopo: o fichário pertence à área Coleção/Binder. Ele só aparece aqui em estado vazio e puxa a média desta área para baixo sem que o fichário populado tenha sido visto. Concordo com 'formulario' para o que foi capturado. Esta área não deve carregar a nota do fichário inteiro.
- **Detalhe da carta (mobile)** — auditor: Melhor tela da área, com identidadeMtg 4 e primeiraImpressao 3. 'A arte é protagonista de verdade'. · revisor: Concordo que é a melhor tela e com a nota, mas aqui o fixture favorece a tela. A captura mostra uma ilustração sem moldura sangrando de borda a borda, o que parece uma arte-herói. Em produção entra a imagem 'normal' do Scryfall, a carta inteira com moldura preta, encostada nas bordas da tela. Os cantos superiores ficam retos (card_detail_screen.dart:301-306 só arredonda embaixo), então os cantos arredondados da própria carta ficam expostos no topo. O auditor citou os cantos, mas não disse que o fixture esconde o problema. Mantenho 3,1 a 3,25. A nota de primeira impressão foi dada sobre uma imagem que a produção não entrega.

**Problemas que o auditor perdeu**

- A tela de erro do detalhe da carta usa o eyebrow errado. card_detail_screen.dart:124-131 monta o AppStatePanel sem passar `status`, então vale o padrão AppStateStatus.information, que é 'PRÓXIMO PASSO' (app_state_panel.dart:61-68). Esse texto aparece em cima de 'Carta indisponível'. O painel já oferece 'AÇÃO INTERROMPIDA', 'SEM CONEXÃO' e 'INDISPONÍVEL', e a tela não usa nenhum. O mesmo template com o mesmo eyebrow aparece no estado inicial da busca. Os estados desenhados são hoje um molde único reaplicado, não estados pensados para cada contexto.
- O detalhe da carta repete três vezes o que a carta já mostra. Em produção a imagem é a carta inteira, que já traz nome, custo, tipo e texto de regras. A tela repete o nome na AppBar, o nome em Fraunces com o custo, o tipo e uma caixa 'Texto de Regras'. O que a imagem não mostra (set, raridade, data e, no futuro, preço, legalidade e outras impressões) fica na tabela chave-valor lá embaixo. O auditor só apontou a duplicação com a AppBar. O problema de composição é maior: ou o herói é art_crop com dados estruturados, ou é a carta inteira com dados que não estão nela.
- Existem goldens de 09/09 em app/test/ui/goldens/runtime/web_mobile/ para sets_catalog, sets_catalog_route, set_detail_tst, latest_set, collection_empty e card_detail_error. Eles mostram o estado atual, e o auditor pontuou pelas capturas de 03/08. No golden de sets_catalog a regressão aparece: mini-carta flutuando num quadro vazio, sem selo de código. No golden do fichário vazio aparecem a dica 'Deslize ou avance para ver os outros filtros.' e dois botões largos.
- Cópia com jargão interno no estado de carregamento do detalhe: 'Buscando os dados canônicos desta impressão.' (card_detail_screen.dart:119-123). 'Canônicos' é vocabulário de engenharia.
- A cor de acento não carrega significado. Rótulos de seção ('Texto de Regras', 'Detalhes'), a barra lateral de 'Resultados para', pílulas de set e foil, ícones de meta e o glifo do fichário vazio são todos azul frost. O dourado aparece em ações, preço e seleção, sem regra visível. No contador a cor significa algo: dourado é coroa ou herói, índigo é noite, tracejado é sem dono. O auditor citou o 'rótulo azul pequeno', mas não tratou o azul como problema de sistema da área.
- Há duas linhas hairline soltas acima e abaixo do AppStatePanel, visíveis em card_search_empty.png e no golden de card_detail_error. Parecem resto de layout e não servem de moldura. O detalhe é pequeno, mas aparece justamente nas duas telas que o auditor aponta como as mais próximas da língua do contador.
- 'Última Edição' não tem botão de voltar nem tratamento próprio. O auditor viu que é a mesma tela do set. Faltou dizer que ela perde a seta de navegação e fica só com o botão de atualizar, o que reforça a impressão de tela de lista reaproveitada.
- A média das notas por tela do auditor (2,89/5) não bate com a notaArea 4,5/10 que ele publicou. A escala usada para converter não está declarada. Isso dificulta comparar esta área com as outras do mesmo levantamento.

**Afirmações de código conferidas**

- ✅ card_search_screen.dart:365-376: o TextField só define border: InputBorder.none e herda filled, enabledBorder e focusedBorder do tema (app_theme.dart:717-731), o que gera a pílula dupla. — Confere. O Container 'card-search-field-frame' tem altura touchTargetMin, pílula e borda própria. Dentro dele o TextField usa isDense, padding vertical de 9 e autofocus: true. O tema traz filled: true, fillColor surfaceSlate e focusedBorder brass400 1.1 com radiusMd. O resultado é um campo de cerca de 26px com contorno dourado preso ao topo da pílula de 48px. Aparece em card_search_results.png, em card_search_empty.png e ao fundo das duas capturas do seletor de impressão.
- ✅ sets_catalog_screen.dart:594-623: a arte do set virou carta inteira (fullCard, BoxFit.contain) numa caixa de 84x56. É regressão do commit e6737c53b, que removeu art_crop, setArt, o selo de código e o símbolo SVG. — Confere. O SizedBox tem 84x56. Usa CardArtworkVariant.fullCard, constrainAspectRatio: false e ScryfallImageHelper.withVersion(..., 'normal'). O git show e6737c53b (10/08/2026, 'feat: complete ManaLoom UX audit packs') remove version: 'art_crop', CardArtworkVariant.setArt, Key('set-code-badge-...'), SetIconSvgCache e SvgPicture.string. O golden de 09/09 confirma a regressão.
- ✅ O símbolo do set e os variants setArt e artCrop são código morto. SetIconSvgCache e iconSvgUri existem, mas nenhuma tela os renderiza. — Confere. Um grep em app/lib mostra que setArt e artCrop só aparecem na definição (card_artwork.dart:16-17, 94, 99). SetIconSvgCache só é referenciado no próprio arquivo e no teste. iconSvgUri só aparece em mtg_set.dart. O fallback _SetIconArtwork atual pinta um ManaLoomGlyph genérico sobre gradiente dourado, não o símbolo do set.
- ✅ card_detail_screen.dart:322-353: sem URL de imagem, a tela cai numa caixa cinza com Icons.style e 'Sem imagem', em vez do verso BrewTact. — Confere. O ramo !hasImage monta AspectRatio, Container surfaceSlate com borda outlineMuted, Icon(Icons.style, 48) e o texto 'Sem imagem'. O verso pintado só aparece via CardArtwork quando a URL existe e falha. Atenuante: effectiveImageUrl cai para fallbackImageUrl (busca por nome), então o caso de URL nula deve ser raro em produção.
- ✅ A tela de detalhe da carta não tem nenhuma ação (adicionar, impressões, preço). — Confere. Um grep por Button, onPressed e onTap nas 722 linhas só encontra voltar (111-113, 168-171), toque na imagem para ampliar (313) e fechar o fullscreen (376).
- ✅ set_cards_screen.dart:366-396: o cabeçalho abre com 4 chips antes do nome, e o nome vem em Inter fontXl w700. Em 430-483: ListTile com miniatura de 64px e CardEditionMetadataLine redundante. — Confere linha a linha. Há um Wrap com _InfoChip(código), _StatusChip, _InfoChip(data) e _InfoChip('N/N cartas'). Em seguida vem Text(set.name) sem fontFamily display. O leading é um SizedBox(height: 64) com AspectRatio 488/680. O CardEditionMetadataLine repete setName e o ano em cada linha.
- ✅ A Fraunces aparece em só uns 4 pontos da área. — Confere. Um grep por displayFontFamily e headline* encontra: card_detail_screen.dart:407 (headlineSmall), collection_screen.dart:222, card_search_screen.dart:1313-1316 (título do diálogo de adicionar) e card_printing_picker.dart:291. No golden novo há ainda o título do AppStatePanel.
- ✅ binder_screen.dart:1582-1608: quatro _FilterDropdown (DropdownButton em 1838-1839). card_search_screen.dart:877-878: miniatura de 54x74, com spotlight de 126x176 só em grid/desktop. card_printing_picker.dart:30: showModalBottomSheet com miniatura de 58x82. — Confere em todos os pontos. Além dos 4 dropdowns há um _SetCodeFilterField (campo de texto) na mesma régua. O spotlight depende de useGrid && visibleResults.length == 1 (card_search_screen.dart:620). _AddCardDialog (1284) e a prévia do deck (deck_details_dialogs.dart:354-359) são Dialog de fato.

## Fichário/coleção: importação em lote, editor, scanner

**Auditor 3.5 → revisor 4** · formulário · auditor foi *justo*

Não. Esta área não está no nível do contador: dou 3,5/10, nível 'formulário' com bolsões de 'correto-genérico'. A distância é de gramática, não de acabamento. O contador é feito de objetos (tiles com estado dentro, miniaturas, numerais serifados enormes, gradiente e profundidade, um herói dourado). O Fichário é feito de controles Material sobre placas chapadas com contorno de 1px. Evidência objetiva no código: em binder_item_editor.dart e binder_import_screen.dart não há nenhum LinearGradient nem BoxShadow; a serifada Fraunces é usada explicitamente uma única vez nas três features (collection_screen.dart:222, o título 'Coleção'), fora o que o tema empresta ao título do AlertDialog e ao AppStatePanel. O editor de carta (core_02/core_03) é o catálogo exato do que o dono rejeita: modal bottom sheet, segmentado, linha rotulada com stepper, duas fileiras de chips, três switches, dois campos de texto empilhados, botão largo e caixa de erro genérica. A importação em lote funciona e trata estados com cor por item (verde/âmbar/vermelho), mas cada carta é um mini-formulário de 5 a 7 controles com a arte reduzida a 58x82, o 'plano' é uma caixa cinza com '3 (2 → 5)' em texto pequeno, a confirmação é um AlertDialog com parede de texto e jargão, e o sucesso é indistinguível da revisão. Sobre fixtures: os versos genéricos de carta nas capturas são artefato — em produção CardArtwork/CachedCardImage carregam arte real — então não puni isso; puni o fato de o layout de importação não dar protagonismo à arte. O editor dá (180x252 como herói) e é a melhor tela capturada, junto do tile dourado de edição selecionada. Lacunas de evidência: não existe nenhuma captura do scanner (avaliei só por código; tem o melhor uso de arte e o único uso de símbolos de mana da área, mas estados de erro/permissão genéricos), não há captura do fichário populado, e core_04 é a página do harness de teste, não tela de produto (excluída da nota). Metade da distância se fecha barato (serifada nos títulos e numerais, CTA fixo, miniaturas maiores, tiles de numerais, recolher dropdowns, copy); a outra metade exige redesenhar o editor e a triagem de importação como superfícies de objetos em vez de formulários.

- **Melhor tela:** Editor de carta — topo (core_01_collection_editor.png): a arte como herói e o tile dourado da edição selecionada são o mais perto que a área chega da gramática do contador. O scanner pode ser melhor, mas não há captura para confirmar.
- **Pior tela:** Editor de carta — validação inline (core_02_collection_inline_validation.png): segmentado + stepper rotulado + duas fileiras de chips + três switches + dois campos de texto + caixa de erro, sem herói, sem arte e sem CTA no viewport.

### Notas por tela

| Tela | Obj | Hier | Tipo | Mat | MTG | Resp | Est | 1ªimp | Média | Veredito |
|---|---|---|---|---|---|---|---|---|---|---|
| Importar coleção — origem (colar lista) | 2 | 3 | 2 | 2 | 2 | 3 | 3 | 2 | 2.4 | formulário |
| Importar coleção — fila de revisão com duplicatas | 2 | 2 | 2 | 2 | 2 | 2 | 3 | 2 | 2.1 | formulário |
| Importar coleção — plano antes de aplicar | 2 | 2 | 2 | 2 | 2 | 2 | 3 | 2 | 2.1 | formulário |
| Importar coleção — confirmação (AlertDialog) | 1 | 3 | 3 | 2 | 1 | 3 | 2 | 2 | 2.1 | formulário |
| Importar coleção — falha parcial | 2 | 2 | 2 | 2 | 2 | 1 | 3 | 2 | 2.0 | formulário |
| Importar coleção — retry com sucesso | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2.0 | formulário |
| Importar coleção — histórico + resumo de disponibilidade | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2.0 | formulário |
| Fichário vazio (aba Coleção > Fichário > Tenho) | 2 | 3 | 3 | 2 | 2 | 3 | 2 | 2 | 2.4 | correto, genérico |
| Editor de carta — topo (arte + edições) | 3 | 3 | 2 | 2 | 3 | 3 | 2 | 3 | 2.6 | correto, genérico |
| Editor de carta — validação inline (preço) | 1 | 1 | 1 | 1 | 1 | 3 | 2 | 1 | 1.4 | formulário |
| Editor de carta — falha ao salvar | 1 | 2 | 1 | 1 | 1 | 3 | 2 | 1 | 1.5 | formulário |
| core_04 — harness de teste (NÃO é tela de produto; fora da nota) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0.0 | correto, genérico |
| Scanner de carta (SEM captura na lista — avaliado só por código, baixa confiança) | 3 | 3 | 2 | 2 | 4 | 3 | 2 | 3 | 2.8 | correto, genérico |

#### Importar coleção — origem (colar lista)

Captura: `docs/qa/ui-live/current/ux-pack-02-collection-import-web-mobile/binder_import_00_source.png`

**Problemas**

- O centro da tela é um TextField multilinha de 9 linhas com label flutuante ('Lista da coleção') — é literalmente um formulário de colar texto (binder_import_screen.dart:485-507).
- Caixa 'FORMATOS ACEITOS' é um retângulo chapado com contorno de 1px e texto monospace (binder_import_screen.dart:451-483): cara de documentação, não de produto.
- Título 'Traga sua caixa para o Fichário' usa titleMedium sans w900 (binder_import_screen.dart:428-436); a Fraunces não aparece em nenhum ponto acima da dobra.
- Dois CTAs competem: o botão dourado largo 'Criar fila de revisão' no corpo e o 'Revisar plano' desabilitado na barra inferior, que ainda cobre o título serifado do painel 'A fila aparecerá aqui'.
- Nenhuma arte de carta, nenhum símbolo de mana, nenhuma pista visual de que isto é Magic; só um glifo de fichário de 22px.

**Acertos**

- O painel 'PRÓXIMO PASSO / A fila aparecerá aqui' (AppStatePanel) tem ilustração própria com órbitas e cartas-fantasma e título em serifada — é o único elemento desenhado da tela, mas fica abaixo da dobra e cortado pela barra de ação.
- Botão primário dourado é inequívoco.

#### Importar coleção — fila de revisão com duplicatas

Captura: `docs/qa/ui-live/current/ux-pack-02-collection-import-web-mobile/binder_import_01_review_duplicates.png`

**Problemas**

- Cada carta vira um mini-formulário: botão contornado 'Trocar impressão', stepper em pílula, dois DropdownButtonFormField (Condição/Idioma) e um FilterChip 'Foil físico' — 5 controles de peso igual por item (binder_import_screen.dart:824-841, 871, 897, 924).
- A arte da carta é uma miniatura de 58x82 (binder_import_screen.dart:721-723). O verso genérico da captura é artefato de fixture — em produção CardArtwork -> CachedCardImage carrega image_url real (core/widgets/card_artwork.dart:262) — mas o layout não dá protagonismo à arte: ela ocupa ~7% do cartão.
- Sopa de chips colada no nome ('Pronta', '2 linhas', 'Escolher impressão') e linha de metadados 'CMM #396 • Foil disponível • Commander Masters • Uncommon' em texto corrido.
- Pílulas de contagem '1' e '1' no cabeçalho sem rótulo visível (binder_import_screen.dart:673-683): o usuário precisa adivinhar que verde = prontas e âmbar = pendentes.
- Quantidade '3' é texto de corpo w900 dentro de uma pílula (binder_import_screen.dart:968-972); no contador esse número seria um numeral serifado enorme.
- Superfície do cartão é surfaceSlate chapado com borda de 1px colorida (binder_import_screen.dart:707-714); zero gradiente, zero sombra no arquivo inteiro.

**Acertos**

- Cor com significado: borda verde para pronta, âmbar para pendente, aviso âmbar no topo para linha inválida.
- O agrupamento de duplicatas é comunicado no próprio item ('2 linhas').

#### Importar coleção — plano antes de aplicar

Captura: `docs/qa/ui-live/current/ux-pack-02-collection-import-web-mobile/binder_import_02_plan.png`

**Problemas**

- O 'plano' — o momento mais importante do fluxo — é uma caixa cinza com duas linhas de texto: 'Atualizar  Sol Ring • 3 (2 → 5)' em fontSm (binder_import_screen.dart:1143-1190). O diff 2→5 deveria ser numeral expressivo com a miniatura da carta.
- Título 'Plano antes de persistir' é jargão de engenharia.
- Os cartões de candidato continuam exibindo dropdowns e steppers acima, de modo que o plano fica no rodapé de um scroll de formulários.
- Barra inferior é texto cinza pequeno ('1 criar • 1 atualizar') + FilledButton: barra Material genérica (binder_import_screen.dart:1032-1099).

**Acertos**

- Chips 'Atualizar'/'Criar' distinguem as ações por cor.
- CTA 'Aplicar lote' dourado é claro.

#### Importar coleção — confirmação (AlertDialog)

Captura: `docs/qa/ui-live/current/ux-pack-02-collection-import-web-mobile/binder_import_03_confirmation.png`

**Problemas**

- É um AlertDialog padrão sobre scrim (binder_import_screen.dart:128-150) — exatamente o padrão 'modal' que o dono do produto rejeita.
- Corpo é parede de texto com jargão: '1 pendência(s) ficarão no rascunho. Um retry do mesmo plano não soma cópias novamente.'
- Os números (1 criado, 1 atualizado, 1 pendência) estão enterrados em frase; não há numeral, miniatura nem objeto.
- Nenhuma identidade MTG.

**Acertos**

- Único ponto do fluxo de importação onde a Fraunces aparece de verdade (título 'Aplicar lote revisado?' herda headlineSmall do tema).
- Dois botões com hierarquia correta (texto vs dourado preenchido).

#### Importar coleção — falha parcial

Captura: `docs/qa/ui-live/current/ux-pack-02-collection-import-web-mobile/binder_import_04_partial_failure.png`

**Problemas**

- O cartão com falha empilha 7 controles: 'Buscar carta', 'Trocar impressão', stepper, 2 dropdowns, chip foil e o X — é a tela mais apertada da área.
- Chip 'Retry necessário' e mensagem 'A quantidade mudou desde a revisão.' são texto pequeno vermelho; o erro não é desenhado, só colorido.
- 'Revisar' / 'Atualizado' no resumo do plano continuam sendo linhas de texto fontSm.
- Nenhum ponto focal: borda vermelha de 1px com alpha 0.28 é sutil demais para dizer 'olhe aqui'.

**Acertos**

- O erro mora no item que falhou e diz a causa, em vez de um toast genérico.
- A barra inferior troca o CTA para 'Revisar falhas' e resume '1 concluída • 1 para revisar'.

#### Importar coleção — retry com sucesso

Captura: `docs/qa/ui-live/current/ux-pack-02-collection-import-web-mobile/binder_import_05_retry_success.png`

**Problemas**

- O estado de sucesso é visualmente idêntico ao estado de revisão: os mesmos cartões, com os mesmos dropdowns e steppers ainda ativos depois de a carta já ter sido criada. A única mudança é um chip 'Criada'.
- Não existe momento de recompensa: nenhuma contagem grande ('2 cartas no Fichário'), nenhum herói dourado, nenhuma arte em destaque.
- Texto da barra '2 concluída(s) • 0 para revisar' com plural entre parênteses.

**Acertos**

- CTA 'Voltar ao Fichário' com check é claro.

#### Importar coleção — histórico + resumo de disponibilidade

Captura: `docs/qa/ui-live/current/ux-pack-02-collection-import-web-mobile/binder_import_06_history.png`

**Problemas**

- Histórico é ExpansionTile + ListTile denso com ícone Material genérico e texto '1 aplicada(s) • 0 falha(s)' + timestamp (binder_import_screen.dart:1225-1263) — padrão de tela de configurações.
- Faixa de disponibilidade '6 Tenho  1 Alocadas  5 Livres  0 Em troca / 0 Faltam' é um Wrap de número+rótulo no mesmo tamanho (binder_import_screen.dart:1118-1130); quebra deixando '0 Faltam' órfão na segunda linha. São exatamente os dados que pediam 5 numerais serifados grandes.
- Três blocos empilhados sem herói (histórico, cabeçalho da fila, faixa, cartões).

**Acertos**

- Os dados certos estão presentes (tenho/alocadas/livres/em troca/faltam) — falta só tratá-los como objeto visual.

#### Fichário vazio (aba Coleção > Fichário > Tenho)

Captura: `app/test/ui/goldens/runtime/web_mobile/collection_empty.png`

**Problemas**

- Cinco camadas de cromo antes do conteúdo: AppBar, abas Fichário/Ofertas/Trocas/Edições, sub-abas Tenho/Quero, campo de busca, trilho de dropdowns 'Condição: todas / Raridade: todas / Idioma' e ainda uma linha de instrução 'Deslize ou avance para ver os outros filtros.' (binder_screen.dart:1465-1760, 1815-1839). Filtros de uma lista vazia.
- O estado vazio é uma caixa chapada feita à mão com ícone de 48px e dois botões Material (binder_screen.dart:579-669), em vez do AppStatePanel ilustrado que o próprio fluxo de importação usa.
- Nenhuma arte, nenhuma carta-fantasma, nada que mostre como o fichário ficará quando cheio.
- Metade inferior da tela é vazio preto.

**Acertos**

- Título 'Coleção' em Fraunces (collection_screen.dart:222) — a única ocorrência explícita da serifada nas três features auditadas.
- CTA dourado 'Importar lista' é o ponto focal correto; copy curta e útil.

#### Editor de carta — topo (arte + edições)

Captura: `docs/qa/ui-live/current/core-product-android/core_01_collection_editor.png`

**Problemas**

- É um showModalBottomSheet rolável (binder_item_editor.dart:61) com ~2 telas de altura; o botão primário 'Adicionar' só aparece no fim do scroll (binder_item_editor.dart:1252).
- Título 'Adicionar — Sol Ring' em sans bold fontXl (binder_item_editor.dart:448-457): o nome da carta merecia a serifada display.
- Preço de mercado é uma pílula pequena com contorno ('Preço de mercado: US$ 12.50', binder_item_editor.dart:483-508) — dado de valor tratado como legenda.
- Tiles de edição são só texto (código, ano, preço, raridade) em trilho de 78px de altura (binder_item_editor.dart:632): sem miniatura da impressão e sem símbolo do set, embora o app já tenha set_icon_svg_cache.dart na feature collection.
- Abaixo da arte a tela vira formulário: 'Lista' segmentado, linha 'Quantidade', chips.

**Acertos**

- Arte da carta 180x252 centralizada como herói. O verso genérico na captura é fixture: em produção CardArtwork usa imageUrl da impressão selecionada com fallback Scryfall por nome (binder_item_editor.dart:467-477), então haveria arte real com bom protagonismo.
- Tile da edição selecionada com preenchimento e borda dourada de 2px é o objeto mais próximo da gramática do contador em toda a área.
- A arte troca quando se troca a edição — comportamento visual correto.

#### Editor de carta — validação inline (preço)

Captura: `docs/qa/ui-live/current/core-product-android/core_02_collection_inline_validation.png`

**Problemas**

- Tela inteira é o catálogo do que o dono rejeita: controle segmentado Tenho/Quero (binder_item_editor.dart:838-945), linha rotulada 'Quantidade' com stepper (949-986), duas fileiras de ChoiceChip (1002, 1044), três SwitchListTile (1074, 1093, 1112) e dois TextField contornados empilhados (1138, 1176).
- Sem herói e sem CTA visível neste viewport; a arte da carta já rolou para fora.
- Erro 'Informe um preço válido maior que zero.' é uma caixa vermelha genérica no rodapé (binder_item_editor.dart:1203-1221), longe do campo Preço, que continua com borda neutra.
- Tudo em sans de um tamanho só; o '1' da quantidade é fontXl bold, sem expressão.
- Nenhum elemento MTG: foil é um ícone Material 'flare' ao lado de um switch.

**Acertos**

- Cores dos switches têm significado (dourado para venda).
- Espaçamento vertical folgado; nada está apertado.

#### Editor de carta — falha ao salvar

Captura: `docs/qa/ui-live/current/core-product-android/core_03_collection_persistence_failure.png`

**Problemas**

- Mesma superfície de configurações da tela anterior, agora com botão dourado largo de ponta a ponta 'Adicionar' (binder_item_editor.dart:1252-1279).
- Erro de persistência é a mesma caixa vermelha de texto: 'Não foi possível salvar esta carta. Revise os dados e tente novamente.' — sem ícone, sem ação de retry dedicada, sem desenho.
- Preço 'R$ 12,50' digitado em campo de texto de corpo; é o número mais importante da tela e não tem peso tipográfico.

**Acertos**

- O erro é inline e persistente (não é snackbar), com liveRegion para acessibilidade.
- CTA visível e único.

#### core_04 — harness de teste (NÃO é tela de produto; fora da nota)

Captura: `docs/qa/ui-live/current/core-product-android/core_04_collection_retry_success.png`

**Problemas**

- A captura mostra a página do harness 'Coleção · jornada de cadastro' definida em app/integration_test/core_product_acceptance_runtime_test.dart, não uma tela do app. Notas 0 = não avaliável; excluída da nota da área.
- Achado real por trás dela: o sucesso ao salvar no editor é só Navigator.pop (binder_item_editor.dart, fluxo _save) — não existe estado de sucesso desenhado para capturar.

#### Scanner de carta (SEM captura na lista — avaliado só por código, baixa confiança)

Captura: `nenhuma (não há PNG de scanner em docs/qa/ui-live/current nem em app/test/ui/goldens)`

**Problemas**

- Não consegui julgar com o olho: nenhuma captura do scanner existe no repositório. As notas vêm da leitura de scanner/screens/card_scanner_screen.dart e scanner/widgets/scanned_card_preview.dart.
- Estado 'não encontrada' é TextField 'Digite o nome correto' + OutlinedButton 'Tentar Novamente' (scanned_card_preview.dart:701-730).
- Estado de permissão negada é ícone + texto + ElevatedButton.icon genérico (card_scanner_screen.dart:760-800).
- Barra de ação é fileira de badges pequenos de 13px (condição, set, foil) sobre surfaceSlate com borda de 0.5px (scanned_card_preview.dart:221-260); nome da carta em sans, sem serifada.
- Lista de edições usa miniaturas de 28x40.

**Acertos**

- A carta reconhecida aparece como arte cheia (CardArtworkVariant.fullCard, até 360px de altura, scanned_card_preview.dart:98-118) — o maior protagonismo de arte da área.
- Custo de mana renderizado com ícones (_ManaCostIcons) e ponto de raridade: é o único lugar da área com símbolos de mana.

### Cheiros de formulário (arquivo:linha)

- `app/lib/features/binder/widgets/binder_item_editor.dart:61` — Editor inteiro é um showModalBottomSheet rolável de ~2 telas; o padrão 'modal' rejeitado pelo dono.
- `app/lib/features/binder/widgets/binder_item_editor.dart:448` — Título 'Adicionar — <carta>' em sans bold fontXl; nome da carta sem a serifada display.
- `app/lib/features/binder/widgets/binder_item_editor.dart:483` — Preço de mercado como pílula pequena com contorno e fontSm, em vez de numeral expressivo.
- `app/lib/features/binder/widgets/binder_item_editor.dart:632` — Trilho de edições com 78px de altura e tiles só de texto; sem miniatura da impressão nem símbolo do set.
- `app/lib/features/binder/widgets/binder_item_editor.dart:838` — Controle segmentado Tenho/Quero feito à mão (dois Containers com borda 1px).
- `app/lib/features/binder/widgets/binder_item_editor.dart:949` — Linha rotulada 'Quantidade' + stepper; numeral em sans fontXl.
- `app/lib/features/binder/widgets/binder_item_editor.dart:1002` — Fileira de ChoiceChip para Condição (NM/LP/MP/HP/DMG).
- `app/lib/features/binder/widgets/binder_item_editor.dart:1044` — Fileira de ChoiceChip para Idioma.
- `app/lib/features/binder/widgets/binder_item_editor.dart:1074` — SwitchListTile 'Foil' (seguido de mais dois em 1093 e 1112: troca e venda) — três switches empilhados.
- `app/lib/features/binder/widgets/binder_item_editor.dart:1138` — TextField contornado 'Preço (R$)' e, em 1176, TextField 'Notas (opcional)' empilhados.
- `app/lib/features/binder/widgets/binder_item_editor.dart:1203` — Erro como caixa vermelha genérica no rodapé, longe do campo que falhou.
- `app/lib/features/binder/widgets/binder_item_editor.dart:1252` — Botão largo de ponta a ponta no fim do scroll; ação primária fora do primeiro viewport.
- `app/lib/features/binder/widgets/binder_item_editor.dart:363` — AlertDialog para confirmar remoção.
- `app/lib/features/binder/screens/binder_import_screen.dart:94` — AlertDialog de descarte; em 130, AlertDialog 'Aplicar lote revisado?' com parede de texto e jargão ('retry', 'pendência(s)').
- `app/lib/features/binder/screens/binder_import_screen.dart:451` — Caixa chapada 1px 'FORMATOS ACEITOS' com texto monospace.
- `app/lib/features/binder/screens/binder_import_screen.dart:485` — TextField multilinha (9–16 linhas) como centro da tela de origem.
- `app/lib/features/binder/screens/binder_import_screen.dart:511` — FilledButton largo 'Criar fila de revisão' e, em 537, OutlinedButton largo 'Abrir sessão de scanner' empilhados.
- `app/lib/features/binder/screens/binder_import_screen.dart:673` — _CountPill '1' / '1' sem rótulo visível no cabeçalho da fila.
- `app/lib/features/binder/screens/binder_import_screen.dart:707` — _CandidateCard: Container surfaceSlate chapado com borda 1px; nenhum gradiente/sombra no arquivo.
- `app/lib/features/binder/screens/binder_import_screen.dart:721` — Arte da carta confinada a 58x82 dentro do cartão de candidato.
- `app/lib/features/binder/screens/binder_import_screen.dart:824` — OutlinedButton.icon 'Buscar carta' e (831) 'Escolher/Trocar impressão' dentro de cada item.
- `app/lib/features/binder/screens/binder_import_screen.dart:871` — DropdownButtonFormField 'Condição' e (897) 'Idioma' repetidos em cada carta.
- `app/lib/features/binder/screens/binder_import_screen.dart:924` — FilterChip 'Foil físico' por carta.
- `app/lib/features/binder/screens/binder_import_screen.dart:1032` — Barra de ação Material: texto cinza fontSm + FilledButton.
- `app/lib/features/binder/screens/binder_import_screen.dart:1118` — _AvailabilityStrip: Wrap de número+rótulo no mesmo tamanho; '0 Faltam' fica órfão na segunda linha.
- `app/lib/features/binder/screens/binder_import_screen.dart:1143` — _PlanSummary 'Plano antes de persistir': caixa cinza com linhas de texto '3 (2 → 5)' em fontSm.
- `app/lib/features/binder/screens/binder_import_screen.dart:1225` — _HistoryPanel: ExpansionTile + ListTile denso com ícones Material e 'aplicada(s) • falha(s)'.
- `app/lib/features/binder/screens/binder_screen.dart:579` — Estado vazio feito à mão: caixa chapada + ícone 48px + Wrap de botões (638-667), ignorando o AppStatePanel ilustrado.
- `app/lib/features/binder/screens/binder_screen.dart:1465` — _SearchFilterBar: TextField + trilho de dropdowns + FilterChips (1625-1728) + linha de instrução 'Deslize ou avance…'.
- `app/lib/features/binder/screens/binder_screen.dart:1815` — _FilterDropdown com DropdownButton ('Condição: todas', 'Raridade: todas').
- `app/lib/features/scanner/widgets/scanned_card_preview.dart:701` — Estado 'não encontrada' do scanner: TextField 'Digite o nome correto' + OutlinedButton.
- `app/lib/features/scanner/screens/card_scanner_screen.dart:777` — Estado de permissão de câmera: ícone + texto + ElevatedButton.icon genérico.

### Ganhos rápidos

- Aplicar AppTheme.displayFontFamily (Fraunces) onde hoje é sans: nome da carta no editor (binder_item_editor.dart:448), 'Fila de candidatos' (binder_import_screen.dart:655), 'Traga sua caixa…' (428), quantidades (editor:971, import:968) e preços. Hoje a serifada aparece explicitamente uma única vez nas três features (collection_screen.dart:222).
- Fixar o botão 'Adicionar/Salvar' no rodapé do sheet do editor para que a ação primária esteja sempre visível (hoje fica no fim de ~2 telas de scroll).
- Transformar 'Preço de mercado' de pílula fontSm em numeral serifado grande ao lado/abaixo da arte.
- Aumentar a miniatura do _CandidateCard de 58x82 para ~96x134 e sobrepor a quantidade como numeral serifado no canto da arte.
- Recolher Condição/Idioma/Foil do cartão de importação em um único badge compacto 'NM · EN' que expande ao toque; o cartão padrão fica só arte + nome + numeral + status.
- Refazer _AvailabilityStrip como 5 mini-tiles de largura igual com numeral serifado grande sobre rótulo pequeno (resolve também o '0 Faltam' órfão).
- No _PlanSummary, mostrar miniatura + '2 → 5' em numerais grandes; renomear 'Plano antes de persistir'.
- Trocar o estado vazio manual do fichário (binder_screen.dart:579) pelo AppStatePanel ilustrado e esconder busca/filtros enquanto a lista está vazia.
- Rotular as pílulas de contagem do cabeçalho (ícone + 'prontas'/'pendentes').
- Limpar a copy: remover plurais '(s)', 'Retry necessário', 'persistir', 'pendência(s)'.
- No estado de sucesso da importação, ocultar os controles dos itens já aplicados e abrir com um herói dourado '2 cartas no Fichário'.
- Marcar o próprio campo Preço em vermelho e posicionar a mensagem junto dele, em vez da caixa no rodapé.
- Gerar capturas do scanner e do fichário populado — hoje a área mais visual não tem nenhuma evidência.

### Redesenhos necessários

- Editor de carta como 'carta sobre a mesa' em um único viewport, sem modal rolável: arte grande como herói; edições como trilho de miniaturas reais com símbolo do set (set_icon_svg_cache já existe); Tenho/Quero como dois tiles grandes com estado dentro; quantidade como numeral serifado gigante com −/+ laterais; condição como 5 tiles com escala visual de desgaste; foil como brilho aplicado na própria arte; troca/venda como tiles que acendem, com o preço como numeral dentro do tile de venda. Elimina os 3 SwitchListTile, os 2 TextField e as fileiras de chips.
- Importação como 'mesa de triagem': grade de 2–3 colunas de tiles de arte com numeral de quantidade e status no próprio quadro (brilho verde/âmbar/vermelho); toque abre o detalhe da carta; colar texto vira caminho secundário; plano como diff visual; sucesso e falha parcial como momentos desenhados.
- Substituir o AlertDialog de aplicação por um tile herói dourado na própria página (equivalente ao 'PASSAR A VEZ') com numerais '1 nova · 1 atualizada'.
- Cabeçalho do Fichário: colapsar as 5 camadas de navegação/filtro; filtros como tiles com símbolos de mana/raridade em vez de dropdowns 'Condição: todas'.
- Histórico de lotes como linha do tempo visual com miniaturas das cartas do lote, não ListTile.
- Scanner: depois de capturado, revisar os estados 'não encontrada' e 'permissão' e a barra de badges de 13px — só dá para dimensionar com capturas.

### Contestação do revisor

O veredito do auditor é justo: a área está no nível "formulário", longe do contador de vida. As discordâncias são de calibragem e não mudam a conclusão.

Abri a referência do contador, as 12 capturas listadas e mais 2 que encontrei fora da lista, e formei minha nota antes de reler a dele. O contador é feito de tiles com estado dentro, numerais serifados grandes, gradiente, profundidade e um herói dourado. O Fichário é feito de controles Material sobre placas chapadas com borda de 1px.

Conferi 11 afirmações arquivo:linha e 10 batem exatamente. Os dois arquivos principais não têm nenhum gradiente ou sombra. A serifada Fraunces aparece explicitamente uma única vez nas três features. A miniatura da importação tem 58x82. O editor tem três switches e dois campos de texto empilhados. O sucesso ao salvar é só `Navigator.pop`. A captura `core_04` é a página do harness de teste, não tela de produto.

Onde ele foi duro demais:
- **Editor contado três vezes.** `core_01`, `core_02` e `core_03` são o mesmo bottom sheet em scrolls diferentes. A falta de herói e de CTA em `core_02` vem da rolagem do teste.
- **Origem da importação.** Colar lista é um caso legítimo de campo de texto. O defeito está no entorno, não no campo.
- **Nota-síntese.** O 3,5/10 dele fica abaixo da média da própria rubrica, que dá cerca de 4,2/10.

Onde ele foi generoso demais:
- **Scanner.** Ganhou as notas mais altas da área (identidade 4, primeira impressão 3) sem nenhuma captura. Deveria ficar fora da nota.

A afirmação de que não há captura do fichário populado é falsa. `binder_physical_identity.png`, em `ux-pack-01-completion-web`, mostra a lista principal, que é a tela mais usada da área e ficou sem avaliação. Ela piora o quadro: cada carta tem 9 chips, uma miniatura de 48x68 e a quantidade "×3" como chip pequeno. Os stat cards acima da lista são chapados e o quarto fica cortado na borda.

Ele também perdeu:
- Moeda misturada na mesma superfície (US$ 12.50 e R$ 12,50), além de "R$ 24.50" com ponto decimal.
- Inglês cru em UI pt-BR ("uncommon", "Non-foil", "Em trade") e data em formato ISO.
- Linha de metadados redundante no editor.
- O título "Plano antes de persistir" continua na tela depois de o lote ser aplicado.
- Pílulas de contagem mostrando "0" sem rótulo visível.
- Idioma com 8 chips quebrando em duas linhas no modo edição.

O tratamento de fixture dele está correto. Os versos genéricos de carta e o badge vermelho nas miniaturas são artefatos, e `binder_editor_identity.png` prova que o editor com arte real tem um herói decente. Foi certo punir a importação por não dar espaço à arte.

Nota revisada: 4,0/10, nível formulário. O editor com arte real é a melhor tela da área. A metade inferior do editor e a lista populada são as piores.

**Discordâncias**

- **Nota da área (3,5/10)** — auditor: notaArea 3.5, descrita no resumo como '3,5/10'. · revisor: A nota-síntese não bate com a rubrica dele. A média das 8 notas por tela (sem core_04) dá 2,11/5 = 4,2/10 com o scanner, e 4,1/10 sem ele. Ele arredondou para baixo sem explicar. Minha nota revisada é 4,0/10 na mesma escala. A diferença é pequena e o nível 'formulário' continua correto, por isso marco 'justo' e não 'duro-demais'.
- **Editor de carta — validação inline (core_02) e falha ao salvar (core_03)** — auditor: Tratou core_01, core_02 e core_03 como três telas separadas. Deu hierarquia 1 a core_02 por estar 'sem herói e sem CTA visível neste viewport'. · revisor: As três capturas são o mesmo bottom sheet em posições de scroll diferentes; o teste rolou até o rodapé para mostrar o erro. A falta de herói e de CTA em core_02 vem dessa rolagem. O problema real, o CTA não fixo, já foi cobrado em core_01, então a mesma superfície foi punida três vezes. Como superfície única, o editor merece cerca de 2,2/5 (objetos 2, hierarquia 2, tipografia 1-2, material 2, identidade 3, respiro 3, estados 2, primeira impressão 2-3), e não a média 1,8 que sai das três linhas dele. O diagnóstico do conteúdo está certo: a metade inferior tem segmentado, stepper rotulado, duas fileiras de chips, três switches e dois campos de texto, que é o que o dono rejeita. A captura binder_editor_identity.png (ux-pack-01-completion-web), com arte real, confirma que o topo do editor fica razoável em produção.
- **Scanner (sem captura)** — auditor: identidadeMtg 4 e primeiraImpressao 3 avaliados só por código. São as notas mais altas da área, e ele marcou baixa confiança. · revisor: Foi generoso sem base. 'Primeira impressão' é um critério visual e não se julga lendo Dart. Confirmei que fullCard até 360px e _ManaCostIcons existem (scanned_card_preview.dart:99-106, 175, 528). O mesmo arquivo tem, porém, a barra de badges de 13px, o TextField 'Digite o nome correto' e o ElevatedButton genérico de permissão. O scanner deveria ficar fora da nota, como core_04, e ser registrado apenas como lacuna de evidência. Com ele dentro, a média sobe artificialmente.
- **Importar coleção — origem (binder_import_00_source)** — auditor: Apontou o TextField multilinha como o cheiro de formulário central e disse que 'dois CTAs competem'. · revisor: Foi um pouco duro. Colar uma lista de texto é um caso em que o campo de texto é a forma certa, como em login. O que falha é o entorno: título em sans, caixa 'FORMATOS ACEITOS' com cara de documentação, nenhuma pista de MTG, e o único elemento desenhado (AppStatePanel) fica abaixo da dobra e cortado pela barra inferior. O 'Revisar plano' está desabilitado e acinzentado, então a competição entre CTAs é fraca. O defeito real é a barra cobrir o título serifado do painel. As notas 2-3 que ele deu estão adequadas; discordo só da ênfase.
- **Importar coleção — confirmação (AlertDialog)** — auditor: objetosVisuais 1 e identidadeMtg 1 por ser um AlertDialog padrão. · revisor: Foi levemente duro. Confirmar uma escrita em lote irreversível é um dos poucos lugares em que um diálogo se justifica, e esta é a única peça do fluxo com Fraunces e hierarquia de botões limpa. O problema é a copy ('pendência(s)', 'retry', 'não soma cópias novamente') e os números enterrados em frase. Eu daria 2 nos dois critérios. Como o dono rejeita modal explicitamente, a punição dele é defensável.
- **Lacuna de evidência: 'não há captura do fichário populado'** — auditor: Afirmou que não existe nenhuma captura do fichário populado no repositório. · revisor: A afirmação é falsa. Existe docs/qa/ui-live/current/ux-pack-01-completion-web/binder_physical_identity.png (390x844, com arte real), além de binder_editor_identity.png e binder_add_editor_identity.png. Estão fora da lista que ele recebeu, mas no mesmo diretório 'current'. A lista populada é a tela mais vista da área, ficou sem avaliação e reforça o veredito dele. Os detalhes estão em problemas perdidos.

**Problemas que o auditor perdeu**

- Fichário populado (binder_physical_identity.png): o item da lista principal é uma sopa de chips. São 9 rótulos por carta ('TST #001', 'Non-foil', '×3', 'NM', 'PT-BR', 'Disponível 2', 'Em trade 1', 'Troca', 'R$ 24.50'), com miniatura de apenas ~48x68 (binder_screen.dart:1913-1914) dentro de um Card surfaceSlate com borda hairline (binder_screen.dart:1892-1900). A quantidade '×3' é um chip pequeno, não um numeral. É a tela mais usada da área e o auditor não a avaliou.
- 'Resumo da coleção' no fichário populado: fileira de _StatCard chapados de 82px de largura (binder_screen.dart:1363-1384) com o 4º card ('100 Faltam') cortado na borda direita, sem indicação de scroll. Os números usam sans pequeno. São os mesmos dados da _AvailabilityStrip, com o mesmo defeito.
- Moeda e locale inconsistentes na mesma superfície. O preço de mercado aparece como 'US$ 12.50' e '$12.50' nos tiles (binder_item_editor.dart:500), ao lado do campo de venda 'R$ 12,50'. Na lista, 'R$ 24.50' usa ponto decimal (binder_screen.dart:2026, toStringAsFixed). O usuário compara dólar com real sem conversão nem explicação.
- Idioma misturado em UI pt-BR: 'uncommon • Foil', 'rare • Non-foil', 'Rare', 'Uncommon', 'Em trade' (binder_screen.dart:2000) e data ISO '2024-02-23'. O auditor apontou 'retry' e 'persistir', mas não viu o inglês cru vindo da API em raridade e foil.
- Linha de metadados redundante no editor: abaixo do trilho de edições, 'SLD #1499 • Non-foil • Secret Lair Drop • Rare • 2024-02-23' repete o que o tile dourado selecionado já mostra. É texto corrido sem função.
- Badge de status sobre a miniatura de 58px na importação. O quadradinho vermelho com ícone em todas as capturas é o _CardArtworkStatusBadge de falha de carga (card_artwork.dart:277-285, ligado por showStatusBadge: selected != null em binder_import_screen.dart:731). É artefato de fixture, mas mostra o layout: o badge cobre ~1/4 da miniatura. Em produção, o badge 'Referência' vai competir com a arte num quadro de 58px.
- Título contradiz o estado: '_PlanSummary' exibe sempre 'Plano antes de persistir' (binder_import_screen.dart:1155), inclusive depois de aplicado, com chips 'Criado' e 'Atualizado' (capturas 04, 05, 06). No histórico pós-sucesso, as pílulas de contagem mostram '0' e '0' sem rótulo visível. O rótulo existe só em Semantics (binder_import_screen.dart:1325-1326).
- Idioma com 8 opções em modo edição (binder_editor_identity.png) quebra em duas linhas de ChoiceChip (EN, PT, PT-BR, ES, FR, DE, IT, JP), com 'PT' e 'PT-BR' lado a lado. É mais sopa de chips do que o fixture de core_01/02 sugere.
- Faixa preta de ~110px acima do sheet em core_01/02/03 e nenhum contexto por trás do modal. O harness abre o sheet sobre página vazia, então o auditor não pôde avaliar como o editor se relaciona com a tela de origem. É uma lacuna de evidência não registrada.

**Afirmações de código conferidas**

- ✅ Em binder_item_editor.dart e binder_import_screen.dart não há nenhum LinearGradient nem BoxShadow. — grep por LinearGradient, RadialGradient, BoxShadow e boxShadow retorna zero nos dois arquivos. A única profundidade é 'elevation: 12' na barra de ação (binder_import_screen.dart:1035).
- ✅ A Fraunces (AppTheme.displayFontFamily) é usada explicitamente uma única vez nas três features (collection_screen.dart:222). — grep por displayFontFamily, Fraunces e fontFamily em features/binder, features/collection e features/scanner devolve só collection_screen.dart:222 e o 'monospace' de binder_import_screen.dart:476.
- ✅ O editor é um showModalBottomSheet (binder_item_editor.dart:61), com título sans fontXl bold em 448-457, arte 180x252 em 465-477 com fallback Scryfall e pílula de preço fontSm em 483-508. — Todas as linhas batem. CardArtwork recebe imageUrl: _selectedImageUrl e fallbackImageUrl: ScryfallImageHelper.namedImageUrl(name). Em produção há arte real, o que binder_editor_identity.png confirma.
- ✅ ChoiceChip em 1002 e 1044, três SwitchListTile em 1074/1093/1112 e TextField em 1138/1176 no editor. — As linhas são exatas.
- ✅ A arte do _CandidateCard fica confinada a 58x82 (binder_import_screen.dart:721-723) num Container surfaceSlate com borda de 1px e alpha 0.28 (707-714). — compact ? 58 : 68 por compact ? 82 : 96. A borda é status.color.withValues(alpha: 0.28).
- ✅ CardArtwork usa CachedCardImage (core/widgets/card_artwork.dart:262), então o verso genérico é artefato de fixture. — Confere em card_artwork.dart:262-276. O placeholder aparece nos estados missing e error. O badge vermelho nas miniaturas da importação vem do mesmo caminho de erro.
- ✅ DropdownButtonFormField em 871/897, FilterChip em 924, OutlinedButton.icon em 824/831, AlertDialog em 94/130 e ExpansionTile + ListTile em 1225/1244 na importação. — Todas as linhas são exatas.
- ✅ _CountPill sem rótulo visível (binder_import_screen.dart:673-683). — O label ('Prontas', 'Pendentes') só vai para Semantics (1325-1326). O Text renderiza apenas '$value'.
- ✅ core_04 é a página do harness definida em integration_test/core_product_acceptance_runtime_test.dart, e o sucesso do editor é só Navigator.pop. — O harness tem 'Coleção · jornada de cadastro' na linha 331 e 'Carta salva · R$' na 339. No editor, 'if (ok) Navigator.pop(context)' está em binder_item_editor.dart:340-341. Não existe estado de sucesso desenhado.
- ✅ Estado vazio do fichário feito à mão (binder_screen.dart:579-669), ignorando o AppStatePanel. — É um Container surfaceElevated com borda strokeThin e ícone de 48px (linhas 579-600). O mesmo arquivo usa AppStatePanel para loading e erro em 548 e 557, então a inconsistência é interna ao arquivo.
- ❌ Não existe captura do scanner nem do fichário populado no repositório. — Para o scanner, a afirmação é verdadeira: find por '*scan*.png' em docs/qa e app/test retorna vazio. Para o fichário populado, é falsa: existem docs/qa/ui-live/current/ux-pack-01-completion-web/binder_physical_identity.png, binder_editor_identity.png e binder_add_editor_identity.png.

## Social: marketplace, trades, mensagens, comunidade, perfis públicos, busca de usuários

**Auditor 4 → revisor 4** · formulário · auditor foi *justo*

Resposta direta: não. A área social/trade não está no nível do contador. Dou 4/10, que é o nível "formulário". No miolo transacional a distância é grande.

Olhei 30 capturas. A área se divide em duas partes bem diferentes.

**Onde já tem cuidado**
- **Estados vazios e de erro (AppStatePanel):** rótulo pequeno em dourado, título em Fraunces e um único botão dourado sobre uma ilustração orbital. É o melhor design da área.
- **Aba Explorar da comunidade:** é a única tela populada com Fraunces nos cards, gradiente e sombra (community_screen.dart:973-985, :1011).
- **Perfil público redesenhado (golden de 9/set):** rótulos de seção em dourado e nome em serifada.

Essas três ficam entre "correto genérico" e "bom abaixo do contador". O material e a voz tipográfica do contador já existem no repositório. Só não foram levados para o resto da área.

**Onde o usuário faz as coisas, é formulário**
- **Marketplace:** cada anúncio empilha 11 a 13 chips. A arte da carta tem 50x70 px dentro de um card de ~380 px. O preço é texto no meio dos chips.
- **Nova Proposta:** é rótulo, caixa cinza com "Nenhum item" e botão contornado, quatro vezes seguidas. A arte das cartas tem 36x50 px. A revisão abre num AlertDialog quase em tela cheia.
- **Detalhes do Trade:** são seis caixas com contorno de 1px e um aviso legal de cinco linhas antes de aparecer qualquer carta. As ações são três botões coloridos sem herói.
- **Detalhe de deck público:** não tem arte do comandante no topo. O feedback é dropdown, campo de texto e botão "Publicar".
- **Busca de usuários e inbox de mensagens:** são linhas de lista com avatar de inicial, sem nada de Magic. A inbox de mensagens foi avaliada só pelo código.

A contagem no código confirma o que o olho vê. Os arquivos create_trade_screen, trade_detail_screen, trade_inbox_screen, marketplace_screen, community_deck_detail_screen, user_search_screen e message_inbox_screen têm zero uso de Fraunces e zero gradiente ou sombra, contra dezenas de Border.all.

**Por que a distância é grande**
- **Cartas em miniatura:** a área existe para trocar cartas, e as cartas são sempre o menor elemento da tela. Não é artefato de fixture. O CardArtwork carrega arte real em produção, mas o layout reserva para ela um espaço mínimo.
- **Números sem destaque:** preço, diferença de valor e estatísticas do perfil aparecem como texto pequeno, sem numeral serifado.
- **Sem metáfora espacial:** não há uma "mesa de troca" que corresponda à mesa viva do contador.

**Lacunas na evidência**
- Trades e Mensagens só têm captura do estado vazio. Pelo código, a versão populada tende a ser lista padrão: o card de trade da inbox nem tem CardArtwork.
- O pacote ux-pack-01-community-web é de 3/ago e mostra versões antigas do perfil e da busca. Precisa ser regenerado.

**Caminho**
Os ganhos rápidos já tiram a área do "formulário" para o "correto": arte maior, preço em Fraunces, e o gradiente do _CommunityDeckCard levado aos outros cards. Também conta trocar as caixas "Nenhum item" por espaços tracejados para carta e levar a aba Cotações para o AppStatePanel. Chegar ao nível do contador exige redesenhar três superfícies: Nova Proposta como mesa de troca, Detalhes do Trade centrado nas cartas e o card de anúncio do Marketplace.

- **Melhor tela:** Estados vazios/erro via AppStatePanel (ex.: Trades vazio, Mensagens vazio) — eyebrow brass + título Fraunces + um CTA dourado sobre ilustração orbital; entre as telas populadas, a melhor é o Perfil público redesenhado (golden de 9/set) empatado com Comunidade - Explorar.
- **Pior tela:** Nova Proposta (create_trade_screen.dart) — formulário empilhado com caixas cinzas 'Nenhum item', artes de 36x50 e zero serifada/gradiente; seguida de perto pelo card do Marketplace (sopa de 13 chips com arte de 50x70).

### Notas por tela

| Tela | Obj | Hier | Tipo | Mat | MTG | Resp | Est | 1ªimp | Média | Veredito |
|---|---|---|---|---|---|---|---|---|---|---|
| Marketplace (lista de ofertas populada) | 2 | 2 | 1 | 2 | 2 | 1 | 4 | 2 | 2.0 | formulário |
| Matches de troca (populada) | 3 | 3 | 3 | 2 | 3 | 3 | 4 | 3 | 3.0 | correto, genérico |
| Nova Proposta (criar trade / contraproposta / oferta indisponível) | 2 | 2 | 1 | 1 | 2 | 3 | 2 | 1 | 1.8 | formulário |
| Revisar proposta (diálogo de confirmação) | 2 | 3 | 3 | 2 | 2 | 2 | 3 | 2 | 2.4 | formulário |
| Detalhes do Trade (pendente / recusado / concluído) | 2 | 2 | 1 | 2 | 2 | 2 | 3 | 2 | 2.0 | formulário |
| Estados vazios e de erro (Trades, Mensagens, Matches, Marketplace, Busca sem resultado, Comunidade Seguindo/Usuários, erro de trade) | 3 | 4 | 4 | 3 | 3 | 5 | 4 | 3 | 3.6 | bom, abaixo do contador |
| Comunidade - aba Explorar (decks públicos) | 3 | 3 | 4 | 3 | 3 | 3 | 4 | 3 | 3.2 | correto, genérico |
| Comunidade - aba Cotações (sem dados) | 1 | 2 | 1 | 1 | 1 | 4 | 1 | 2 | 1.6 | formulário |
| Deck público da comunidade (detalhe + feedback/comentário) | 2 | 2 | 1 | 2 | 2 | 2 | 3 | 2 | 2.0 | formulário |
| Perfil público de jogador | 3 | 3 | 4 | 2 | 3 | 3 | 3 | 3 | 3.0 | correto, genérico |
| Busca de usuários (resultados) | 2 | 2 | 1 | 1 | 1 | 3 | 4 | 2 | 2.0 | formulário |

#### Marketplace (lista de ofertas populada)

Captura: `docs/qa/ui-live/current/ux-pack-05-social-trade-web-mobile/social_trade_01_marketplace_populated.png`

**Problemas**

- Sopa de chips clássica: um único anúncio empilha 13+ pílulas/badges (CMM #392, Non-foil, x1, NM, PT, Troca, Venda, 12 concluídos, 1 cancelamentos, responde ~2.5h, envia ~17.0h) mais uma caixa de referência de preço e uma linha em itálico. O card fica com ~380px de altura para vender UMA carta.
- A arte da carta é um selo de 50x70 px (marketplace_screen.dart:498-500) boiando centralizado verticalmente ao lado de uma coluna de texto de 380px. Em produção a arte é real (CardArtwork -> CachedCardImage com imageUrl da impressão), então o layout está desperdiçando o melhor ativo visual que o app tem.
- Preço 'R$ 18.50' em fontMd bold (marketplace_screen.dart:574-581), no mesmo peso visual de um chip. Num marketplace o preço deveria ser o numeral serifado enorme, como o '40' do contador.
- Barra de filtros estilo configurações: DropdownButton 'Todas' + dois FilterChip retangulares 'Troca'/'Venda' (marketplace_screen.dart:180,204,400-417).
- Zero uso da Fraunces, zero gradiente, zero sombra no arquivo inteiro (contagem: display=0, gradient/shadow=0, 7 bordas de 1px).
- CTA 'Propor troca/compra' é um OutlinedButton de largura total (marketplace_screen.dart:718-720) — botão largo contornado, sem herói.
- Formato de moeda inconsistente: 'R$ 18.50' (ponto) aqui vs 'R$ 18,50' na tela de matches.

**Acertos**

- Dados de confiança do vendedor (concluídos, cancelamentos, tempo de resposta) são informação valiosa — só estão mal materializados.
- Campo de busca com contorno dourado tem presença.
- Estado vazio do marketplace é desenhado (AppStatePanel).

#### Matches de troca (populada)

Captura: `docs/qa/ui-live/current/ux-pack-05-social-trade-web-mobile/social_trade_00_matches_populated.png`

**Problemas**

- Card único com contorno de 1px, fundo chapado; sem gradiente nem profundidade (trade_matches_screen.dart: gradient/shadow=0).
- Arte 72x101 (trade_matches_screen.dart:452-453) é melhor que no marketplace, mas continua sendo miniatura ao lado de uma pilha de tags (Wrap em :285).
- O conceito mais forte da tela — 'esta carta FECHA seu deck' — é um chip laranja 'Falta no deck'. Deveria ser o objeto: a carta encaixando num slot vazio do deck.
- Parágrafo de privacidade com ícone de escudo logo abaixo do título rouba o topo da tela para texto legal.
- Botão dourado largo 'Propor troca' (FilledButton :381) é correto, mas é o padrão 'botão largo' que o dono rejeita.

**Acertos**

- Único título da área transacional em Fraunces ('Cópias para fechar seu deck', headlineSmall :206) — dá identidade imediata.
- Preço em brass com peso e CTA dourado criam uma hierarquia legível: título > carta > preço > ação.
- Densidade controlada: bem menos chips que o marketplace.

#### Nova Proposta (criar trade / contraproposta / oferta indisponível)

Captura: `docs/qa/ui-live/current/ux-pack-05-social-trade-web-mobile/social_trade_03_trade_create_rehydrated.png`

**Problemas**

- É literalmente um formulário: rótulo de seção -> caixa -> botão contornado, quatro vezes seguidas ('Tipo de Negociação', 'Itens que você quer', 'Itens que você oferece', 'Mensagem (opcional)') — _sectionTitle em create_trade_screen.dart:1001,1005,1182,1213.
- Estados vazios internos são caixas cinzas com texto centralizado 'Nenhum item selecionado' / 'Nenhum item oferecido' (create_trade_screen.dart:1506-1525) — exatamente a 'caixa cinza' que o dono rejeita.
- Arte da carta selecionada com 36x50 px (create_trade_screen.dart:1583-1585), menor que o stepper de quantidade ao lado. Numa tela de TROCA DE CARTAS as cartas são o menor elemento.
- Nenhuma metáfora de mesa de troca: não há dois lados (eu | você) se encarando, nem balança visual. O contador tem miniatura da mesa; aqui o equivalente seria dois montes de cartas frente a frente.
- Botões 'Adicionar item' são OutlinedButton pílula (create_trade_screen.dart:1539); mensagem é TextField multilinha cru (:1269); pagamento são TextFields empilhados (:1780-1783); enviar é ElevatedButton largo (:1304).
- Banner de contexto no topo é parede de texto com jargão ('reconfirmados pelo backend') — create_trade_screen.dart:1056.
- Arquivo inteiro: display=0, gradient/shadow=0, 16 bordas de 1px.

**Acertos**

- O seletor de tipo (Troca/Compra/Misto, _typeChip :1397) é o único elemento com cara de azulejo — ícone grande, estado selecionado com cor. É a semente certa, só falta material.
- Cor com significado consistente: brass = o que quero, frost = o que ofereço.

#### Revisar proposta (diálogo de confirmação)

Captura: `docs/qa/ui-live/current/ux-pack-05-social-trade-web-mobile/social_trade_04_trade_create_review.png`

**Problemas**

- É um AlertDialog (create_trade_screen.dart:424-426) ocupando quase a tela toda — o 'modal fullscreen' que o dono explicitamente rejeita.
- Dois blocos de texto (parágrafo de instrução + aviso 'Combinação entre jogadores' de 5 linhas) antes de aparecer qualquer carta. Metade do modal é prosa.
- Artes 44x61 (create_trade_screen.dart:605-607); o resumo de valor ('Diferença: R$ 6.50 (35.1%)') é texto de 12px com ícone de balança em vez de um numeral/gauge expressivo.
- Caixas dentro de caixa dentro de modal: três níveis de contorno de 1px.

**Acertos**

- Título 'Revisar proposta' em Fraunces.
- Hierarquia de ação clara: 'Voltar e editar' texto vs 'Enviar proposta' dourado.
- Estrutura 'Você quer receber' / 'Você oferece' é a espinha certa para um futuro layout frente a frente.

#### Detalhes do Trade (pendente / recusado / concluído)

Captura: `docs/qa/ui-live/current/ux-pack-05-social-trade-web-mobile/social_trade_06_trade_pending_actions.png`

**Problemas**

- Pilha de 6 caixas contornadas antes de ver uma carta: status, aviso legal, participantes, resumo em texto, equilíbrio de valor, botões. As cartas (o assunto do trade) só aparecem abaixo da dobra, com arte de 48x64 (trade_detail_screen.dart:505-508).
- O aviso 'Combinação entre jogadores' (TradeSafetyNotice, trade_detail_screen.dart:148) ocupa a 2a posição da tela em TODOS os estados, inclusive Concluído e Recusado — parede de texto permanente.
- Informação duplicada: 'Você entrega: 1x Counterspell / Você recebe: 1x Arcane Signet' como texto puro (trade_detail_screen.dart:268-300) e logo abaixo de novo como lista com arte.
- 'Equilíbrio de valor' é parágrafo (trade_detail_screen.dart:390-435): 'R$ 6.50 (35.1%)' merecia ser numeral serifado grande com barra de balança, como o '40' de vida.
- Ações como sopa de botões: Aceitar verde, Contrapropor âmbar, Recusar vermelho, todos contornados, em Wrap de duas linhas (_actionButton :999-1019). Não há herói — no contador o equivalente é o tile dourado PASSAR A VEZ.
- Participantes são CircleAvatar com inicial (trade_detail_screen.dart:316) + pílulas '12 concl.' '1 canc.'.
- Confirmações via AlertDialog (:1090, :1443). Arquivo: display=0, gradient/shadow=0.

**Acertos**

- Cabeçalho de status usa cor com significado (âmbar pendente, vermelho recusado, verde concluído) — é o único ponto onde 'o estado mora no objeto'.
- Layout remetente <-> você com seta de troca é o embrião correto de uma mesa de troca.
- Estado de erro da tela é desenhado (AppStatePanel com ícone de retry vermelho).

#### Estados vazios e de erro (Trades, Mensagens, Matches, Marketplace, Busca sem resultado, Comunidade Seguindo/Usuários, erro de trade)

Captura: `docs/qa/ui-live/current/ux-pack-05-social-trade-web-mobile/social_trade_11_trade_inbox_empty.png`

**Problemas**

- É o mesmo template em 8 telas: mesma órbita, mesmos fantasmas de carta, mesmo medalhão — muda só o ícone Material dentro do círculo. Depois da terceira vez vira papel de parede, não ilustração.
- Tudo muito apagado (órbitas a ~10% de opacidade sobre quase-preto): comparado à mesa viva colorida atrás do hub do contador, parece tela desligada.
- Nenhuma arte real de Magic nem símbolo de mana; ícones são Material genéricos (chat_bubble, swap, badge).
- As capturas de Trades e Mensagens SÓ existem no estado vazio — não há prova visual de inbox populada. No código, o _TradeCard (trade_inbox_screen.dart:316-350) usa CircleAvatar + _InfoChip e NÃO tem CardArtwork; _ConversationTile é ListTile + CircleAvatar (message_inbox_screen.dart:184-186). Ou seja, a versão populada tende a ser lista de configurações.

**Acertos**

- É o melhor trabalho de design da área: eyebrow em brass versalete ('PRIMEIRO PASSO'), título em Fraunces, uma frase, UM botão dourado. Hierarquia impecável.
- Cada vazio aponta para o próximo passo real (Encontrar matches, Buscar jogadores, Abrir wishlist) em vez de 'nada aqui'.
- Erro usa a mesma gramática com acento vermelho — estado desenhado, não SnackBar.
- Respiro generoso, zero ruído.

#### Comunidade - aba Explorar (decks públicos)

Captura: `app/test/ui/goldens/runtime/web_mobile/community_public_decks.png`

**Problemas**

- Deck card ainda é 'linha de lista com miniatura': thumb ~55x80 à esquerda, texto e chips à direita, chevron. Um deck público deveria ser um azulejo com a arte do comandante sangrando e pips de identidade de cor.
- Filtros de formato são FilterChip retangulares em fila (community_screen.dart:560) + campo de busca: topo com cara de tela de filtros.
- '0%' de sinergia dentro de um chip com ícone de brilho — numeral sem expressão.
- Quatro abas com ícone+texto + AppBar com dois ícones + banner 'Matches' + busca + chips = 5 faixas de chrome antes do primeiro deck.
- Fixture repete a mesma arte (anel) para decks diferentes; em produção viria a arte real do comandante — mas o espaço reservado é pequeno de qualquer forma.

**Acertos**

- Única tela populada da área que usa Fraunces nos títulos dos cards (community_screen.dart:1011) E gradiente + sombra no card (community_screen.dart:973-985). Dá para sentir a diferença.
- Título 'Comunidade' em serifada no AppBar.
- Banner 'Matches para suas faltantes' conecta comunidade a trade com dado real.

#### Comunidade - aba Cotações (sem dados)

Captura: `app/test/ui/goldens/runtime/web_mobile/community_tab_3.png`

**Problemas**

- Estado feito à mão fora do sistema: Icon(Icons.hourglass_top, 48) + dois Text cinzas (community_screen.dart:1490-1520). Não usa o AppStatePanel que todas as abas vizinhas usam — destoa na hora.
- Sem título serifado, sem eyebrow, sem ação, sem ilustração. Tela preta com ampulheta.
- Copy com exclamação ('Amanhã teremos dados de variação!') fora do tom do resto.

**Acertos**

- Pelo menos explica o porquê (precisa de 2 dias de histórico).

#### Deck público da comunidade (detalhe + feedback/comentário)

Captura: `docs/qa/ui-live/current/ux-pack-05-social-trade-web-mobile/social_trade_14_community_context_comment.png`

**Problemas**

- Detalhe de deck SEM herói de arte: o comandante (Talrand) aparece só lá embaixo como linha de lista com arte 42x60 (community_deck_detail_screen.dart:677-678). A primeira dobra é caixa de texto + botão largo + caixa de texto + caixa de texto.
- Painel de feedback é formulário puro: DropdownButtonFormField 'Comentar sobre' (community_deck_detail_screen.dart:995) + TextField 'Comentar no deck' (:1018) + ElevatedButton 'Publicar' desabilitado (:1056) + nota legal.
- Título do deck em sans bold (fontXxl, :386) — nenhuma Fraunces no arquivo (display=0).
- Curva de mana como pílulas de texto '31 baixo / 22 médio / 8 alto' (_MetricPill :1169) em vez de um gráfico de barras/curva — dado que implora por ser objeto visual.
- 'Copiar para meus decks' é botão dourado de largura total (:559-573); 'Abrir ofertas compatíveis' é OutlinedButton largo (:910).
- Username do fixture sublinhado como link HTML.

**Acertos**

- Símbolos de mana reais aparecem (custo na lista de cartas e pips em 'cores') — único lugar da área com iconografia MTG de verdade.
- Chip de contexto 'Carta - Arcane Signet' no comentário é uma boa ideia de ancoragem.
- Seções por tipo (Comandante, Artefatos) em brass.

#### Perfil público de jogador

Captura: `app/test/ui/goldens/runtime/web_mobile/user_profile_success.png`

**Problemas**

- ATENÇÃO: a captura em docs/qa/ui-live/current/ux-pack-01-community-web/user_profile_success.png (3/ago) está defasada — mostra a versão antiga sem serifada. O golden de 9/set mostra o redesenho. O pacote de evidência precisa ser regenerado.
- Avatar é CircleAvatar com inicial (user_profile_screen.dart:319-320). Num app de Magic a identidade do jogador poderia ser a arte do comandante favorito / identidade de cor.
- Numerais de estatística (1 / 0 / 0) em sans bold fontXl (_StatItem, user_profile_screen.dart:632+) com ícone azul em cima — exatamente onde o contador usaria numerais Fraunces enormes.
- Botões Seguir/Mensagem são par preenchido+contornado padrão; TabBar de 4 abas de texto (:579).
- Cartão de identidade é caixa chapada com contorno (gradient/shadow=0 no arquivo).

**Acertos**

- Eyebrows 'IDENTIDADE PÚBLICA' e 'MESA PÚBLICA' em brass + título serifado 'Decks, comunidade e cartas disponíveis' — a voz tipográfica do contador chegou aqui.
- Nome em Fraunces grande dá personalidade.
- Tile de deck com arte 66x92 (:822-823), comandante nomeado e seta dourada — melhor miniatura de deck da área.

#### Busca de usuários (resultados)

Captura: `docs/qa/ui-live/current/ux-pack-01-community-web/user_search_results.png`

**Problemas**

- Resultado é linha de lista de contatos: CircleAvatar com inicial (user_search_screen.dart:233-234) + nome + '1 decks - 0 seguidores' + chevron (:308). Indistinguível de uma tela de configurações.
- Nada de MTG: nem arte do deck em destaque, nem cores, nem formato favorito.
- Campo de busca dentro de uma faixa cinza de fundo diferente (Container :74) cria um degrau visual estranho sob o AppBar.
- Erro de plural '1 decks'. Sem Fraunces (display=0).

**Acertos**

- Estados vazio/sem-resultado/erro usam AppStatePanel desenhado (no golden de 9/set; a captura de 3/ago do pack-01 mostra a versão antiga em caixa cinza).
- Contorno dourado no campo focado.

### Cheiros de formulário (arquivo:linha)

- `app/lib/features/binder/screens/marketplace_screen.dart:498` — Arte da carta em SizedBox 50x70 dentro de um card de ~380px de altura; a carta (produto à venda) é o menor elemento do anúncio.
- `app/lib/features/binder/screens/marketplace_screen.dart:546` — Dois Wrap de badges seguidos (:546 e :564) + Wrap de _miniTrustChip (:911-950) = sopa de 11-13 chips por anúncio.
- `app/lib/features/binder/screens/marketplace_screen.dart:574` — Preço renderizado como Text fontMd bold no meio de um Wrap de chips; sem numeral display.
- `app/lib/features/binder/screens/marketplace_screen.dart:400` — _ConditionDropdown (DropdownButton, :417) + FilterChip 'Troca'/'Venda' (:180, :204): barra de filtros estilo configurações.
- `app/lib/features/binder/screens/marketplace_screen.dart:720` — CTA 'Propor troca/compra' como OutlinedButton.icon de largura total.
- `app/lib/features/trades/screens/create_trade_screen.dart:1506` — Estado vazio interno = Container cinza com contorno hairline e texto centralizado 'Nenhum item selecionado/oferecido' (caixa cinza).
- `app/lib/features/trades/screens/create_trade_screen.dart:1583` — Arte do item selecionado em 36x50 px, menor que o stepper de quantidade.
- `app/lib/features/trades/screens/create_trade_screen.dart:1001` — Sequência rótulo->caixa->botão via _sectionTitle (:1001, :1005, :1182, :1213): estrutura de formulário empilhado.
- `app/lib/features/trades/screens/create_trade_screen.dart:1539` — OutlinedButton.icon 'Adicionar item' repetido para cada lado da troca.
- `app/lib/features/trades/screens/create_trade_screen.dart:1269` — TextField multilinha cru para mensagem; _buildPaymentFields (:1780-1783) empilha mais TextFields.
- `app/lib/features/trades/screens/create_trade_screen.dart:424` — Revisão da proposta em showDialog/AlertDialog quase fullscreen, com dois parágrafos de texto antes das cartas; artes 44x61 (:605-607).
- `app/lib/features/trades/screens/create_trade_screen.dart:1056` — _buildOriginContextBanner: banner de parede de texto com jargão técnico ('reconfirmados pelo backend').
- `app/lib/features/trades/screens/trade_detail_screen.dart:148` — TradeSafetyNotice (5 linhas de texto legal) fixo na 2a posição em todos os estados do trade, inclusive concluído/recusado.
- `app/lib/features/trades/screens/trade_detail_screen.dart:268` — _buildExchangeSummary: a troca descrita como duas linhas de texto puro dentro de caixa contornada, duplicando a lista de itens abaixo.
- `app/lib/features/trades/screens/trade_detail_screen.dart:390` — _buildValueSummary: equilíbrio de valor como parágrafo; diferença de R$ e % sem numeral expressivo nem visual de balança.
- `app/lib/features/trades/screens/trade_detail_screen.dart:999` — _actionButton: Aceitar/Contrapropor/Recusar como três ElevatedButton tonais contornados em Wrap, sem ação-herói.
- `app/lib/features/trades/screens/trade_detail_screen.dart:505` — Arte dos itens do trade em 48x64, abaixo da dobra, depois de 6 caixas.
- `app/lib/features/trades/screens/trade_detail_screen.dart:1090` — Confirmações de ação e de envio via AlertDialog (:1090, :1443).
- `app/lib/features/trades/screens/trade_inbox_screen.dart:350` — _TradeCard da inbox usa CircleAvatar + _InfoChip (:411-422) e não tem nenhuma CardArtwork: lista de trades sem uma carta à vista.
- `app/lib/features/community/screens/community_deck_detail_screen.dart:995` — Painel de feedback = DropdownButtonFormField 'Comentar sobre' + TextField (:1018) + ElevatedButton 'Publicar' (:1056): formulário clássico.
- `app/lib/features/community/screens/community_deck_detail_screen.dart:677` — Comandante do deck só aparece como linha de lista com arte 42x60; não há herói de arte no topo do detalhe.
- `app/lib/features/community/screens/community_deck_detail_screen.dart:1169` — _MetricPill: curva de mana como pílulas de texto ('31 baixo', '22 médio', '8 alto') em vez de gráfico.
- `app/lib/features/community/screens/community_deck_detail_screen.dart:559` — 'Copiar para meus decks' como ElevatedButton dourado de largura total; 'Abrir ofertas compatíveis' OutlinedButton largo (:910).
- `app/lib/features/community/screens/community_screen.dart:1498` — Aba Cotações: estado sem dados feito à mão (Icon hourglass_top 48 + dois Text cinzas), fora do AppStatePanel usado nas outras abas.
- `app/lib/features/community/screens/community_screen.dart:560` — Filtro de formato como fila de FilterChip retangulares.
- `app/lib/features/social/screens/user_search_screen.dart:233` — _UserSearchCard: CircleAvatar com inicial + texto + chevron (:308) — linha de lista de contatos.
- `app/lib/features/social/screens/user_profile_screen.dart:632` — _StatItem: numerais de decks/seguidores em sans fontXl com ícone; oportunidade perdida de numeral Fraunces grande. Avatar CircleAvatar com inicial (:319).
- `app/lib/features/messages/screens/message_inbox_screen.dart:184` — _ConversationTile = ListTile + CircleAvatar (:186): inbox padrão Material, sem identidade.

### Ganhos rápidos

- Aumentar a arte das cartas em toda a área: marketplace 50x70 -> ~96x134 alinhada ao topo (marketplace_screen.dart:498); create trade 36x50 -> ~64x89 (:1583); trade detail 48x64 -> ~72x100 (:505). Em produção a arte é real (CardArtwork/CachedCardImage), é o ganho visual mais barato que existe.
- Preço como numeral Fraunces grande (AppTheme.displayFontFamily, ~28-32px, brass) no marketplace (:574), matches e no 'Equilíbrio de valor' do trade (trade_detail_screen.dart:390). Padronizar 'R$ 18,50' com vírgula.
- Aplicar Fraunces nos títulos que hoje estão em sans: nome do deck no detalhe (community_deck_detail_screen.dart:386), label de status do trade (trade_detail_screen.dart:222-228), nome da carta no anúncio, títulos de seção da Nova Proposta.
- Trocar o estado da aba Cotações (community_screen.dart:1490-1520) por AppStatePanel, igual às abas vizinhas.
- Colapsar a sopa de chips do marketplace: set/número/foil numa linha de metadado só; confiança do vendedor em UMA linha compacta (ex.: '12 trocas - responde em ~2h') em vez de 4 pílulas coloridas.
- Tirar o TradeSafetyNotice do topo do trade detail: mostrar completo só em Pendente, e como ícone de escudo com tooltip/expansão nos demais estados; remover o _buildExchangeSummary duplicado (:268).
- Dar ao cabeçalho de status do trade e aos cards de marketplace/matches o mesmo gradiente+sombra que o _CommunityDeckCard já usa (community_screen.dart:973-985) — o material já existe no repo, só não foi propagado.
- Eleger um herói nas ações do trade: 'Aceitar' como tile dourado/verde cheio; Contrapropor e Recusar como secundários discretos.
- Substituir as caixas cinzas 'Nenhum item selecionado' por slots de carta tracejados (mesma linguagem do tile INICIATIVA 'sem dono' do contador) com '+' dentro — o slot vira o botão de adicionar e elimina o OutlinedButton.
- Corrigir '1 decks' (plural) e regenerar o pacote docs/qa/ui-live/current/ux-pack-01-community-web (3/ago), que ainda mostra perfil e busca na versão antiga.

### Redesenhos necessários

- Nova Proposta como MESA DE TROCA: dois lados frente a frente (você | outro jogador) com as cartas em tamanho legível como objetos, slots tracejados para adicionar, e uma balança/numeral central de diferença de valor que reage em tempo real. Tipo de negociação como azulejos com material. Revisão deixa de ser AlertDialog e vira o próprio estado final da mesa com um tile-herói 'Enviar proposta'.
- Detalhes do Trade reorganizado em torno das cartas: herói = as duas pilhas de cartas com arte grande e seta de troca; status como faixa/tile colorido com Fraunces; equilíbrio de valor como numeral + barra; timeline e chat abaixo. Avisos legais fora do caminho crítico. Diálogos de confirmação substituídos por estados inline.
- Card de anúncio do Marketplace redesenhado como azulejo de carta: arte dominante (metade do card ou grade de 2 colunas com arte cheia), preço em numeral serifado, condição/idioma como marca discreta sobre a arte, vendedor em uma linha. Filtros como tiles/segmentos visuais em vez de dropdown+chips.
- Detalhe de deck público com herói de arte do comandante (banner com art crop, identidade de cor em pips de mana, nome em Fraunces), curva de mana como gráfico de barras real, e feedback como thread de comentários com compositor fixo no rodapé (estilo chat) em vez de dropdown+textfield+botão.
- Inbox de Trades e de Mensagens populadas: cards com miniaturas das cartas envolvidas (pilha dupla entrega/recebe) e status colorido, em vez de CircleAvatar + chips/ListTile. Capturar e versionar o estado populado — hoje só existe evidência do estado vazio.
- Identidade de jogador: substituir avatar-inicial por objeto MTG (arte do comandante em destaque / anel de identidade de cor) usado em perfil, busca de usuários, participantes do trade e conversas; resultados de busca como tiles de jogador com o deck em destaque.
- Variar a ilustração do AppStatePanel por contexto (troca, conversa, mercado, jogadores) e subir o contraste — hoje é o mesmo desenho apagado em 8 telas.

### Contestação do revisor

A avaliação do auditor é justa. Mantenho 4/10 e o nível "formulário" para a área social.

**O que fiz**
- Abri a referência do contador e 24 capturas da área.
- Formei minha nota antes de reler a do auditor e cheguei ao mesmo lugar.
- Conferi 14 afirmações arquivo:linha do auditor. Treze conferem integralmente, inclusive a contagem de zero Fraunces, gradiente e sombra nos arquivos transacionais. A do avatar confere só em parte.

**O que vi com o olho**
- **Miolo transacional:** Marketplace, Nova Proposta, revisão, Detalhes do Trade e detalhe de deck público são superfícies estilo configurações. São caixas chapadas com contorno fino, chips empilhados e botões largos. As cartas são sempre o menor elemento da tela (36x50, 44x61, 48x64, 50x70).
- **Telas corretas mas genéricas:** Matches, Comunidade/Explorar e o perfil redesenhado.
- **Melhor trabalho:** os estados vazios do AppStatePanel são de fato o melhor da área. Só que esse é um template do app inteiro e não deve puxar a nota para cima.
- **Arte pequena não é artefato de fixture:** as capturas já mostram arte, e o CardArtwork carrega o CachedCardImage em produção. O layout é que não dá espaço à arte.

**Onde discordo, sem mudar a nota**
- **Duro demais:**
  - Avatar: a inicial é fallback. O código carrega a foto via avatarUrl no perfil, na busca e nas mensagens.
  - Campos: o TextField de mensagem e os campos de pagamento são formulário legítimo.
  - Aviso legal: o aviso no momento de enviar está no lugar certo. O redundante é o parágrafo de instrução acima dele.
- **Generoso ou impreciso:**
  - Usou "display=0" por grep como prova de zero serifada. O tema injeta Fraunces em headlineSmall e titleLarge, e o próprio título "Revisar proposta" que ele elogiou vem daí.
  - Deu identidadeMtg 3 aos estados vazios, que só têm ícones Material genéricos.
  - Deu material 1 à Nova Proposta e 2 ao Marketplace e ao Detalhes do Trade. As três telas usam o mesmo material.

**O que ele perdeu**
- **Moeda:** há um terceiro formato, "R$12.00" sem espaço, em trade_detail_screen.dart:581, convivendo com "R$ 12.00" na mesma tela.
- **Eyebrow de erro:** o erro do trade mostra "PRÓXIMO PASSO" em vermelho porque não passa status: error ao AppStatePanel. O eyebrow certo, "AÇÃO INTERROMPIDA", já existe e não é usado.
- **Avatar dos participantes:** os participantes do trade e a inbox de trades nunca usam avatarUrl, ao contrário do perfil, da busca e das mensagens.
- **Chat sem avaliação:** chat_screen.dart (594 linhas) não tem captura e não foi avaliado.
- **Cotações populada:** a aba com dados usa arte de 36x50 e também não tem captura.
- **Capturas duplicadas:** duas das 30 capturas são duplicatas byte a byte.
- **Ganho barato na AppBar:** trocar appBarTheme.titleTextStyle para a display daria a voz serifada do contador a todos os títulos da área de uma vez. Hoje só "Comunidade" é serifada, por override local.

**Conclusão**
A área social não está no nível do contador, e a distância é maior justamente onde o usuário faz trocas. Os achados novos reforçam o 4/10. Eles mostram inconsistência, não qualidade que o auditor deixou de ver.

**Discordâncias**

- **Perfil público e Busca de usuários (avatar)** — auditor: Avatar é CircleAvatar com inicial. Identidade de jogador sem nada de MTG. · revisor: Em parte é artefato de fixture. O código carrega a foto do usuário quando avatarUrl existe (user_profile_screen.dart:319-324, user_search_screen.dart:233-238). A inicial só aparece porque o usuário do fixture não tem avatar. O que resta válido é que não há identidade MTG (comandante, cores) e que o layout não reserva espaço para isso. A frase do auditor dá a entender que a inicial é o design final. Não muda a nota.
- **Nova Proposta (campo de mensagem e pagamento)** — auditor: Mensagem é TextField multilinha cru (:1269). Pagamento são TextFields empilhados (:1780-1783). · revisor: Duro demais neste ponto. Texto livre e valor em dinheiro são entrada de formulário por natureza, e o próprio contador não teria outra forma para isso. O cheiro de formulário da tela vem da sequência rótulo, caixa cinza e botão contornado, e das cartas em 36x50. O TextField não é o problema. Eu tiraria esses dois itens da lista de cheiros. O veredito 'formulario' da tela continua certo.
- **Revisar proposta (diálogo)** — auditor: Dois blocos de texto antes de qualquer carta. Metade do modal é prosa. · revisor: Concordo só em parte. O aviso 'Combinação entre jogadores' no momento do envio é texto legal no lugar certo: a troca é entre pessoas e o app não protege o pagamento. O redundante é o parágrafo de instrução acima dele ('Confira itens, quantidades...', create_trade_screen.dart:438-439). Ele repete o que o título já diz. A punição deveria cair nesse parágrafo e no fato de ser um AlertDialog. O aviso em si não merece punição.
- **Contagem 'display=0' como prova de zero Fraunces** — auditor: Arquivo inteiro: display=0, logo zero serifada. · revisor: A métrica por grep subestima o uso real. O tema aplica a display a headlineSmall e titleLarge (app_theme.dart:517-524). É por isso que 'Revisar proposta' sai em Fraunces dentro de create_trade_screen.dart sem citar displayFontFamily. O próprio auditor elogiou esse título e, na mesma avaliação, escreveu 'display=0' sobre o arquivo. A conclusão visual dele está certa, porque as telas populadas quase não têm serifada. A contagem só não deveria aparecer como prova absoluta.
- **Estados vazios e de erro (AppStatePanel)** — auditor: Melhor trabalho de design da área. Hierarquia 4, tipografia 4, identidadeMtg 3. · revisor: Um pouco generoso em identidadeMtg. São ícones Material genéricos e contornos-fantasma de carta a cerca de 10% de opacidade, o que para mim vale 2. O auditor também não viu que as duas linhas horizontais finas atravessam a ilustração orbital e parecem divisores soltos. O elogio ao estado de erro ignora um bug de copy, descrito nos problemas perdidos. Mantenho 'bom-abaixo-do-contador'. Lembro ainda que é um template do app inteiro, não mérito da área social, e por isso não deveria puxar a nota da área para cima. O auditor já descontou isso ao dar 4 com média simples de cerca de 4,8.
- **Nova Proposta (material=1 contra Marketplace material=2)** — auditor: Material 1 na Nova Proposta e 2 no Marketplace e no Trade Detail. · revisor: As notas são inconsistentes: as três telas usam o mesmo material (surfaceSlate chapado com contorno fino, zero gradiente e zero sombra). A Nova Proposta ainda tem os azulejos de tipo com estado colorido. Eu daria 2 nas três. A mudança é pequena e não altera o veredito.

**Problemas que o auditor perdeu**

- Há um terceiro formato de moeda dentro da mesma tela. O preço do item no Detalhes do Trade sai como 'R$12.00', sem espaço (trade_detail_screen.dart:581, e :615 para o pagamento). O bloco 'Equilíbrio de valor' logo acima usa 'R$ 12.00', com espaço (:435-445). Matches usa 'R$ 18,50', com vírgula. Isso aparece nas capturas 06, 08 e 10. O auditor só notou a diferença entre ponto e vírgula do marketplace para o matches.
- O eyebrow do estado de erro do trade está errado. trade_detail_screen.dart:112-126 cria o AppStatePanel de erro sem passar status: AppStateStatus.error. O padrão é 'information', e a captura 09 mostra 'PRÓXIMO PASSO' em vermelho sobre 'Não foi possível abrir este trade'. O AppStatePanel já tem o eyebrow certo para erro, 'AÇÃO INTERROMPIDA' (app_state_panel.dart:61-69), que não está sendo usado. O vazio do marketplace tem o mesmo problema: 'Nenhuma carta encontrada' aparece com 'PRÓXIMO PASSO' em vez de 'SEM RESULTADOS'. O auditor elogiou o erro como 'estado desenhado' sem ver isso.
- A identidade do jogador é inconsistente dentro da própria área. Perfil, busca e inbox de mensagens carregam a foto do usuário via avatarUrl. Os participantes do trade (trade_detail_screen.dart:316) e o card da inbox de trades (trade_inbox_screen.dart:350) mostram sempre a inicial sobre um cinza outlineMuted, sem o tom brass usado nas outras telas. O mesmo jogador fica com dois avatares diferentes conforme a tela.
- trade_inbox_screen.dart:354 faz otherUser.label[0] sem checar se o label está vazio. trade_detail :320 e message_inbox fazem essa checagem. Um label vazio quebra o card.
- chat_screen.dart tem 594 linhas e nenhuma captura, e o auditor não o avaliou. A área inclui 'mensagens', e a conversa é a tela onde o usuário passa o tempo. O auditor registrou a lacuna da inbox populada, mas não a do chat. Pelo código, o chat usa CircleAvatar (:269) e TextField (:431), sem CardArtwork, gradiente ou display. É um chat Material padrão.
- Outros estados populados seguem sem evidência, e o auditor não listou estes. A aba Cotações com dados usa _MarketMoverCard com arte de 36x50 (community_screen.dart:1846-1847), o mesmo selo minúsculo criticado nas outras telas. Também faltam Seguindo populada, Usuários com resultados dentro da aba, e as abas Fichário, Seguidores e Seguindo do perfil.
- As 30 capturas contam duplicatas. trades_inbox.png e messages_inbox.png dos goldens são idênticos byte a byte (mesmo md5) a social_trade_11 e social_trade_12 do pack-05. As superfícies distintas com evidência são menos do que o número sugere.
- Os títulos de AppBar são inconsistentes na área. 'Comunidade' usa Fraunces por override local (community_screen.dart:258). 'Matches de troca', 'Nova Proposta', 'Detalhes do Trade', 'Trades', 'Mensagens', 'Perfil' e 'Buscar Usuários' saem em sans, porque appBarTheme.titleTextStyle usa uiFontFamily (app_theme.dart:~616). O auditor citou o título serifado da Comunidade como acerto, mas não viu que trocar essa única linha do tema daria a voz serifada do contador a todas as telas de uma vez.
- O erro de plural também aparece no marketplace: '1 cancelamentos' (marketplace_screen.dart:919) e '${n} concluídos' (:913) não têm singular. O auditor citou a string na sopa de chips, mas só marcou '1 decks' (user_search_screen.dart:282) como erro.
- Na Nova Proposta, o stepper de quantidade ocupa cerca de 110px fixos e corta o nome da coleção ('Commander Masters ...', 'Dominaria Remastere...', captura 07). O mesmo corte aparece no diálogo de revisão e no detalhe do trade ('• Un...'). A informação some para dar lugar a um controle de formulário.
- No marketplace, um anúncio de cerca de 380px de altura significa no máximo dois anúncios por tela em 390x844. O auditor mediu a altura, mas não tirou a consequência: a tela não funciona como vitrine, porque não há o que comparar nem grade para olhar. O fixture tem um único item, então o ritmo da lista real não foi visto por ninguém.
- No Detalhes do Trade pendente, o campo de mensagem fixo no rodapé disputa a atenção com os três botões de ação, e as cartas ficam entre os dois, abaixo da dobra. A captura 06 termina com a primeira carta cortada pelo campo.

**Afirmações de código conferidas**

- ✅ marketplace_screen.dart:498-500 — arte da carta em SizedBox 50x70 com CardArtwork (arte real em produção) — Linhas 498-504: SizedBox(width: 50, height: 70) com CardArtwork(variant: gallery, imageUrl: item.cardPrintingImageUrl, fallbackImageUrl: ...). O CardArtwork chama o CachedCardImage (core/widgets/card_artwork.dart:262). Em produção a arte é real, então o tamanho pequeno é escolha de layout, não artefato de fixture. A captura já mostra arte (o anel), e a crítica não puniu placeholder.
- ✅ marketplace_screen.dart:574-581 — preço como Text fontMd bold dentro do Wrap de chips — Linhas 573-581: Text('R$ ${price.toStringAsFixed(2)}') em fontMd bold brass400, irmão direto dos _statusTag 'Troca'/'Venda'. O toStringAsFixed gera ponto decimal, o que confirma a inconsistência com a tela de matches, que usa vírgula.
- ✅ marketplace_screen.dart:718-720 — CTA 'Propor troca/compra' é OutlinedButton de largura total — Linhas 717-720: SizedBox(width: double.infinity) com OutlinedButton.icon.
- ✅ create_trade_screen.dart:424-426 — revisão em showDialog/AlertDialog — Linhas 424-426: showDialog<bool> com AlertDialog(key: 'create-trade-review-dialog'). O título em Fraunces vem do tema: app_theme.dart:517-524 aplica display() a headlineSmall e titleLarge. Por isso a contagem 'display=0' por grep subestima o uso real da serifada: a tela herda a fonte sem citar displayFontFamily.
- ✅ create_trade_screen.dart:1506-1525 — estado vazio interno é uma caixa cinza com texto centralizado — Linhas 1505-1525: Container surfaceSlate com Border.all hairline e Text(emptyText) centralizado.
- ✅ create_trade_screen.dart:1583-1585 — arte do item com 36x50 — Linhas 1583-1586: SizedBox(width: 36, height: 50) com CardArtwork.
- ✅ create_trade_screen.dart:1056 — banner com o jargão 'reconfirmados pelo backend' — O método _buildOriginContextBanner começa na linha 1056. A string 'reconfirmados pelo backend' está na linha 1152. A citação aponta para o método, não para a string, mas o conteúdo confere.
- ✅ trade_detail_screen.dart:148 — TradeSafetyNotice fixo na 2ª posição em todos os estados — Linha 148: const TradeSafetyNotice(compact: true), sem condição de status, logo depois de _buildStatusHeader. As capturas 06, 08 e 10 (pendente, recusado e concluído) mostram o aviso nos três estados. Mesmo no modo compact ele ocupa 5 linhas.
- ✅ trade_detail_screen.dart:268 e :390 — resumo da troca e equilíbrio de valor como texto — _buildExchangeSummary está em :268 e _buildValueSummary em :390. As strings são montadas em :435-445 com toStringAsFixed.
- ✅ trade_inbox_screen.dart:316-350 — _TradeCard sem CardArtwork, com CircleAvatar e _InfoChip — O arquivo inteiro tem 0 ocorrências de CardArtwork/CachedCardImage. O CircleAvatar está em :350 e os _InfoChip em :411-422.
- ✅ community_screen.dart:973-985 e :1011 — gradiente, sombra e Fraunces no _CommunityDeckCard — O LinearGradient está em :970-977, o BoxShadow em :981-987 e fontFamily: displayFontFamily em :1011. O gradiente vai de surfaceSlate 0.98 a surfaceElevated 0.62 e quase não aparece na captura. O material existe, mas é tímido.
- ✅ community_screen.dart:1490-1520 — aba Cotações com estado feito à mão, fora do AppStatePanel — Linhas 1490-1520: Icon(Icons.hourglass_top, size: 48) e dois Text em textSecondary.
- ✅ Contagem por arquivo: zero Fraunces, zero gradiente e zero sombra nos arquivos transacionais — Refiz a contagem. marketplace, create_trade, trade_detail, trade_inbox, community_deck_detail, user_search e message_inbox têm 0 de displayFontFamily, 0 de Gradient( e 0 de BoxShadow/elevation. trade_matches tem 1 display, user_profile tem 2 e community_screen tem 4 display, 2 gradient e 2 shadow.
- ❌ user_profile_screen.dart:319-320 e user_search_screen.dart:233-234 — avatar é CircleAvatar com inicial — Confere só em parte. Os dois usam backgroundImage: CachedNetworkImageProvider(user.avatarUrl) quando avatarUrl existe (user_profile :319-324, user_search :233-238, message_inbox :186-191). A inicial é o fallback, e o fixture não tem avatarUrl. Já em trade_detail_screen.dart:316 e trade_inbox_screen.dart:350 o avatar é sempre a inicial: esses dois nunca consultam avatarUrl.

## Perfil, autenticação, planos/checkout, legal, overlays críticos

**Auditor 4 → revisor 4.5** · correto, genérico · auditor foi *duro-demais*

Resposta direta: NÃO. Esta área não está no nível do contador — está a uma distância grande, nota 4/10, e o núcleo dela (Perfil, diálogos de conta, Cadastro, Planos) é exatamente o que o dono chama de feio: página de Configurações, modais com campos empilhados, sopa de chips e paredes de texto.

O que eu vi (39 PNGs abertos; checkout/upgrade/plans têm o mesmo md5 porque /checkout e /upgrade redirecionam para /plans, e ux_pack08_11 é byte-idêntica à 08): a gramática do contador — tiles como objetos, estado dentro do objeto, um herói dourado, numerais Fraunces gigantes, material com gradiente e profundidade, tudo visível de uma vez — simplesmente não existe aqui. O Perfil próprio é um cartão chapado com avatar de inicial 'M', pílulas de status e linhas ícone+texto+seta, seguido de seções com hairline, um TextField, botões contornados de 1px com larguras aleatórias e um rodapé com botão cinza desabilitado; não há uma única arte de carta, símbolo de mana ou numeral na tela mais pessoal do app. Toda ação de conta abre um AlertDialog Material com TextFormFields (trocar senha = 3 campos; excluir conta = parágrafo + 2 campos vermelhos; foto = colar uma URL). Planos é ~90 palavras de jurídico-operacional com chips tipo 'Teto operacional, não comercial' e uma barrinha de 8px para o único número que importa (120). Cadastro são 4 campos + bloco de consentimento de 215px que empurra o CTA para fora da dobra. Nos overlays de outras áreas, o editor do fichário acerta a arte-herói mas termina em segmented + 13 chips + 3 switches + textarea, e o trade mostra cartas em miniaturas de 40px dentro de um AlertDialog com parede de texto.

O que se salva: o sistema compartilhado tem bons ossos — Fraunces nos títulos, paleta abyss/brass/frost coerente, botão primário com gradiente dourado no login, AppStatePanel com estados realmente desenhados e cor semântica, barra de salvar do perfil com 4 estados, e o vazio 'Primeiro deck' (ilustração + título display + CTA), que é a única tela 'boa, abaixo do contador'. Login, verificação de email, perfil público e painéis de estado são 'corretos e genéricos'. Nada é quebrado ou desleixado: tudo funciona, tem acessibilidade (live regions, keys, alvos de toque) e consistência. O cuidado aqui foi de engenharia e de conformidade, não de direção de arte.

Por que a distância: (1) escolhas e dados são linhas e campos, nunca objetos; (2) identidade MTG é praticamente zero no núcleo da área — arte real via CachedCardImage só aparece em telas emprestadas de decks/fichário/trade, e quase sempre como miniatura acessória; (3) material é caixa chapada com contorno de 1px — os gradientes declarados (heroGradient, cardWeave) são imperceptíveis nas capturas; (4) nenhum numeral expressivo; (5) a copy vaza jargão interno ('capability', 'servidor', 'all-OFF', 'superfícies de produto'). Há uma dúzia de ganhos baratos (numerais display, esconder a barra de salvar, breakpoint do consentimento, reaproveitar AppStatePanel nos diálogos, limpar a copy), mas eles levam a área de 4 para uns 5,5. Para chegar ao nível do contador, Perfil, diálogos de conta, Planos e a casca de cadastro precisam ser redesenhados na gramática de tiles — não retocados.

- **Melhor tela:** Decks — primeiro uso (visual_system_06_decks_first_use.png): única com ilustração-herói, título display grande e CTA dourado óbvio. Dentro do núcleo da área (auth/perfil/planos), a melhor é o Login, pelo botão com gradiente dourado e a marca serifada — ainda assim só 'correto-genérico'.
- **Pior tela:** Planos/Checkout/Upgrade (plans_success.png, três capturas byte-idênticas): parede de texto jurídico + sopa de chips com jargão de engenharia + barra de progresso de 8px, sem herói, sem ação, sem numeral, zero MTG. Empatada de perto com a metade 'conta e segurança' do Perfil próprio, que é uma página de Configurações pura com um botão cinza morto como rodapé.

### Notas por tela

| Tela | Obj | Hier | Tipo | Mat | MTG | Resp | Est | 1ªimp | Média | Veredito |
|---|---|---|---|---|---|---|---|---|---|---|
| Perfil próprio — cartão de identidade (topo) | 2 | 3 | 3 | 2 | 1 | 3 | 3 | 2 | 2.4 | correto, genérico |
| Perfil próprio — conta, segurança e barra de salvar (dirty/saving/erro/salvo) | 1 | 2 | 3 | 1 | 0 | 3 | 3 | 1 | 1.8 | formulário |
| Perfil público (outro jogador) | 3 | 3 | 3 | 2 | 3 | 4 | 3 | 3 | 3.0 | correto, genérico |
| Decks — primeiro uso (estado vazio desenhado) | 4 | 5 | 4 | 3 | 3 | 4 | 4 | 4 | 3.9 | bom, abaixo do contador |
| Painéis de estado (sem resultados, offline, indisponível, sessão expirada, permissão negada) | 3 | 4 | 3 | 2 | 2 | 4 | 4 | 3 | 3.1 | correto, genérico |
| Diálogos do perfil (foto por URL, contas bloqueadas, trocar senha, encerrar sessões, excluir conta) | 1 | 3 | 3 | 2 | 0 | 3 | 2 | 1 | 1.9 | formulário |
| Overlay de deck — menu de ação e confirmação de exclusão | 2 | 4 | 2 | 2 | 2 | 4 | 3 | 3 | 2.8 | correto, genérico |
| Seletor de comandante (estado recuperado) | 2 | 2 | 2 | 2 | 3 | 3 | 2 | 2 | 2.2 | correto, genérico |
| Fichário — folha 'Editar carta' (erro de edições, recuperado, confirmar remoção, erro ao salvar) | 3 | 3 | 2 | 2 | 4 | 2 | 3 | 3 | 2.8 | correto, genérico |
| Trade — nova proposta, seletor de itens, revisão e erro de envio | 2 | 3 | 2 | 2 | 2 | 2 | 3 | 2 | 2.2 | formulário |
| Login | 2 | 4 | 4 | 3 | 1 | 4 | 2 | 3 | 2.9 | correto, genérico |
| Cadastro (vazio e erro de consentimento) | 1 | 3 | 3 | 2 | 1 | 2 | 3 | 2 | 2.1 | formulário |
| Planos / Checkout / Upgrade (Beta gratuita) | 1 | 2 | 3 | 2 | 0 | 2 | 2 | 1 | 1.6 | formulário |
| Legal — Termos e privacidade | 1 | 3 | 3 | 1 | 1 | 3 | 2 | 2 | 2.0 | correto, genérico |
| Verificar email (deslogado) | 2 | 3 | 4 | 3 | 1 | 4 | 2 | 3 | 2.8 | correto, genérico |

#### Perfil próprio — cartão de identidade (topo)

Captura: `docs/qa/ui-live/current/ux-pack-07-visual-system-web-mobile/visual_system_00_profile_clean.png`

**Problemas**

- O 'herói' do perfil é um CircleAvatar com a inicial 'M' (profile_screen.dart:1066) — placeholder genérico de qualquer app SaaS. Nenhuma arte de carta, comandante favorito, identidade de cor ou símbolo de mana: a tela mais pessoal do app não tem nada de Magic.
- Nome serifado truncado em duas linhas ('Marina — Arquivista de Co…') dentro de um cartão chapado surfaceSlate com borda brass de 1px (profile_screen.dart:958-962). O motif cardWeave (intensity 0.72) é praticamente invisível na captura — o material lê como caixa cinza com contorno.
- Estado mora em pílulas de texto ('Perfil não publicado', 'Email verificado' — _IdentityBadge, profile_screen.dart:1547) em vez de morar no objeto, como o tile COROA dourado do contador.
- 'ATALHOS DA CONTA' são linhas rotuladas ícone+texto+seta (_IdentityDestination, profile_screen.dart:1594) — exatamente a gramática de tela de Configurações que o dono rejeita.
- Nenhum numeral expressivo: o perfil próprio não mostra decks, partidas, vitórias, coleção. O contador tem '2', '4', '40' enormes; aqui o maior número da tela é nenhum.
- Copy vazando jargão interno na UI: 'Recursos públicos e de produto só aparecem quando autorizados pelo servidor' (profile_screen.dart:1173) e 'publicação exige capability liberada' (1184).

**Acertos**

- Eyebrow 'IDENTIDADE DE JOGADOR' em brass com tracking + nome em Fraunces dão um começo de voz própria.
- Espaçamento interno do cartão é confortável; nada está apertado.
- Cor com algum significado: brass para identidade, frost para @usuario.

#### Perfil próprio — conta, segurança e barra de salvar (dirty/saving/erro/salvo)

Captura: `docs/qa/ui-live/current/ux-pack-07-visual-system-web-mobile/visual_system_01_profile_dirty.png (também 02, 03, 04 e ux_pack08_00_profile_security_below_fold.png)`

**Problemas**

- É literalmente uma página de Configurações: seção = hairline no topo + caixinha de ícone 36px + título + subtítulo (_ProfileSectionPanel, profile_screen.dart:2293-2343), seguida de botões contornados de 1px empilhados ('Trocar senha', 'Contas bloqueadas', 'Exportar meus dados' — profile_screen.dart:1406, 1493, 1499) e links de texto ('Encerrar outras sessões' 1412, 'Excluir minha conta' 1518).
- Um único campo de formulário 'Nick / Apelido' (TextField, profile_screen.dart:1186) é todo o conteúdo editável visível — e ele ganha uma seção inteira com título, subtítulo e ícone.
- Rodapé permanente com botão largo 'Salvar alterações' cinza desabilitado (FilledButton full-width, profile_screen.dart:854-868) sobre Material chapado com hairline (870-882). Na maior parte do tempo o elemento mais pesado da tela é um botão morto.
- Cerca de 150px de vazio preto entre 'Excluir minha conta' e a barra de salvar (SizedBox space112 em 1228 + conteúdo curto): a tela termina sem composição.
- Botões com larguras arbitrárias alinhados à esquerda (Wrap em 1402 e 1489) criam uma borda direita serrilhada — cara de protótipo.
- Zero identidade MTG. Zero objeto visual. Zero numeral.
- Quando as capabilities forem liberadas piora: _buildVisibilityGrid (profile_screen.dart:1300-1383) empilha até 6 DropdownButtonFormField (_VisibilityField, 1696) + dropdown de Estado (1234) + TextField cidade (1247) + textarea de notas (1283) — parede de dropdowns.

**Acertos**

- A barra de status tem os 4 estados desenhados com cor e ícone próprios (brass 'Alterações não salvas', spinner 'Salvando', vermelho com mensagem, verde 'Alterações salvas') — profile_screen.dart:820-853. Funcionalmente é o ponto mais cuidado da tela.
- Títulos de seção em Fraunces mantêm um fio de identidade tipográfica.
- Destrutivo em vermelho, separado dos demais.

#### Perfil público (outro jogador)

Captura: `docs/qa/ui-live/current/ux-pack-07-visual-system-web-mobile/visual_system_05_public_profile.png`

**Problemas**

- Numerais 2 / 284 / 73 em sans bold ~16px (_StatItem, user_profile_screen.dart:632) — é exatamente onde a serifada display gigante do contador deveria aparecer e não aparece.
- Avatar de inicial em círculo (user_profile_screen.dart:319) e nome truncado ('Pilota Azorius e organiza…').
- Arte de carta existe mas é miniatura de 66x92 (CachedCardImage, user_profile_screen.dart:820-823) dentro de linha de lista com seta — a arte é acessório, não protagonista. Em produção é arte real via CachedCardImage; as duas linhas com a mesma carta são artefato do fixture.
- Sem pips de identidade de cor nos decks; 'Commander', '100 cartas', 'Sinergia 87%' são texto colorido corrido.
- TabBar padrão Material (user_profile_screen.dart:579) com 4 abas de texto: Decks/Seguidores/Seguindo/Fichário.
- Inconsistência: título da AppBar 'Perfil' aqui em sans, no perfil próprio em Fraunces. 'Deixar de seguir' e 'Mensagem' com larguras diferentes empilhados à esquerda.
- Cartão de identidade é caixa chapada com contorno de 1px; nenhum gradiente ou profundidade.

**Acertos**

- Tem dados como quase-objetos: trio de estatísticas com ícone, linhas de deck com arte real.
- Eyebrows 'IDENTIDADE PÚBLICA' / 'MESA PÚBLICA' + subtítulo serifado criam ritmo editorial.
- Respiro bom, leitura imediata.

#### Decks — primeiro uso (estado vazio desenhado)

Captura: `docs/qa/ui-live/current/ux-pack-07-visual-system-web-mobile/visual_system_06_decks_first_use.png`

**Problemas**

- Leque de cartas é silhueta vetorial com o glifo da marca, não arte de Magic; metade inferior da tela é vazio preto.
- Material ainda tímido: brilho brass sutil, sem a profundidade/gradiente dos tiles do contador.

**Acertos**

- Única tela do conjunto com ilustração-herói, título display grande ('Sua mesa começa com uma lista'), CTA dourado óbvio e ação secundária discreta. É a prova de que o sistema sabe fazer bonito quando quer.
- Hierarquia impecável em 1 segundo.

#### Painéis de estado (sem resultados, offline, indisponível, sessão expirada, permissão negada)

Captura: `docs/qa/ui-live/current/ux-pack-07-visual-system-web-mobile/visual_system_07_no_results.png (também 08, 09 e ux_pack08_20_session_expired.png, ux_pack08_21_permission_denied.png)`

**Problemas**

- A ilustração (órbitas + contornos de carta, app_state_panel.dart:213 _StateVisual) está com opacidade tão baixa que some: a tela lê como preto com um ícone Material num círculo.
- Título serifado pequeno (~17px, app_state_panel.dart:357) — sem contraste de escala; o eyebrow colorido quase compete com ele.
- Os cinco estados são o mesmo template trocando ícone e cor; nenhum tem personalidade própria (offline poderia ser uma mesa apagada, sessão expirada uma ampulheta de mana, etc.).
- Bloco não é centralizado verticalmente: ~230px vazios embaixo, duas hairlines soltas delimitando o painel.
- Ícones genéricos Material (cloud_off, hourglass_disabled, lock_clock).

**Acertos**

- Estados SÃO desenhados e consistentes: eyebrow com cor semântica (vermelho offline/sessão, brass indisponível, frost sem resultados), título display, uma ação dourada clara.
- Copy humana e curta ('O que já foi carregado continua seguro').
- Muito acima do padrão spinner+texto.

#### Diálogos do perfil (foto por URL, contas bloqueadas, trocar senha, encerrar sessões, excluir conta)

Captura: `docs/qa/ui-live/current/ux-pack-08-critical-overlays-web-mobile/ux_pack08_05_profile_password_validation.png (também 01, 02, 03, 04, 06, 07)`

**Problemas**

- São AlertDialog Material puros com TextFormField empilhados: trocar senha = 3 campos + caixa de dica (profile_screen.dart:1914-1995), excluir conta = parágrafo + link + instrução + 2 campos (2100-2180), encerrar sessões (2034-2062). É o 'modal com campos de texto empilhados' que o dono cita nominalmente como feio.
- Alterar foto = colar uma URL HTTPS num campo (_AvatarUrlDialog, profile_screen.dart:1803-1862). Sem galeria, sem preview, sem escolher arte de carta como avatar — é um formulário de desenvolvedor exposto ao usuário, e a maior oportunidade MTG perdida da área.
- Contas bloqueadas: carregando = CircularProgressIndicator solto numa caixa de 152px (profile_screen.dart:528-538); erro = texto centralizado + TextButton (556-568); lista = ListTile só com texto, sem avatar (631). Estados genéricos, nada desenhado — contrasta com o AppStatePanel que o próprio app já tem.
- Validação pinta tudo de vermelho ao mesmo tempo (2 a 3 campos com borda + mensagem) — o diálogo de exclusão vira uma parede vermelha e rosa.
- Botão 'Excluir definitivamente' rosa-claro largo abaixo de 'Cancelar' desalinhado à direita: composição quebrada em 390px.
- Superfície do diálogo é caixa chapada surfaceElevated sem gradiente; scrim simples.

**Acertos**

- Títulos em Fraunces dão unidade.
- Caixa de dica de senha com ícone de escudo é legível e bem posicionada.
- Hierarquia de ações (texto vs preenchido dourado) está correta.

#### Overlay de deck — menu de ação e confirmação de exclusão

Captura: `docs/qa/ui-live/current/ux-pack-08-critical-overlays-web-mobile/ux_pack08_10_deck_delete_confirmation.png (também 08, 09; 11 é byte-idêntica à 08)`

**Problemas**

- Confirmação não mostra a arte do deck que está sendo destruído, embora ela esteja logo atrás no card (Dialog em deck_list_screen.dart:1121-1154). O objeto some justamente no momento em que mais importa.
- Título 'Excluir deck?' em sans, enquanto os diálogos do perfil e do fichário usam Fraunces — inconsistência tipográfica entre overlays irmãos.
- Menu de ação é um PopupMenu padrão com um único item 'Excluir' — um menu para uma opção.
- Caixa chapada com contorno rosado de 1px.

**Acertos**

- Ícone de lixeira em tile, nome do deck + formato + contagem dentro do diálogo: contexto claro.
- Par de botões equilibrado (Cancelar contornado / Excluir deck preenchido).
- A tela por trás (card do deck com arte de Atraxa, pips de mana reais, '100/100', 'Validado') é de longe a coisa mais próxima do contador em todo o pacote — mas pertence à área de Decks.

#### Seletor de comandante (estado recuperado)

Captura: `docs/qa/ui-live/current/ux-pack-08-critical-overlays-web-mobile/ux_pack08_12_commander_selection_recovered.png`

**Problemas**

- O comandante — a carta mais importante de um deck Commander — aparece como miniatura de 48x67 (deck_commander_selector.dart:197-198) numa linha de lista, com 'Remover' e 'Trocar' como TextButtons (271). Deveria ser o herói, com a arte ocupando o tile.
- Tudo em sans; rótulo 'Comandante (opcional)' é label de formulário.
- A captura é um harness isolando o componente (resto da tela preto), então o vazio é artefato do fixture — mas a miniatura minúscula é do layout.

**Acertos**

- Tem arte real (CachedCardImage) e pips de mana WUBG verdadeiros — identidade MTG presente, só subdimensionada.
- Borda brass indica seleção.

#### Fichário — folha 'Editar carta' (erro de edições, recuperado, confirmar remoção, erro ao salvar)

Captura: `docs/qa/ui-live/current/ux-pack-08-critical-overlays-web-mobile/ux_pack08_14_binder_printings_recovered.png (também 13, 15, 16)`

**Problemas**

- Metade de baixo é catálogo completo do que o dono rejeita: segmented control Tenho/Quero (binder_item_editor.dart:878/930), sopa de ChoiceChips para Condição (998-1002) e 8 chips de Idioma (1036-1044), três SwitchListTile seguidos Foil/Troca/Venda (1074, 1093, 1112), textarea 'Notas (opcional)' (1176), par de botões largos Remover/Salvar (1231-1252).
- Nenhuma serifada na folha inteira; título 'Editar — Sol Ring' é sans de label. Quantidade '2' num stepper pequeno em vez de numeral display.
- Linha de metadados repetida em texto corrido ('CMM #396 • Sem foil • Commander Masters • Uncommon • 2023-08-04') logo abaixo do carrossel que já diz a mesma coisa.
- Confirmação de remoção é AlertDialog cru com dois TextButtons (binder_item_editor.dart:363).
- Folha muito longa: exige rolar ~1,6 tela para chegar ao Salvar.

**Acertos**

- A arte da carta é herói de verdade (≈180x252, binder_item_editor.dart:466) — o único overlay em que a arte tem protagonismo.
- Carrossel de edições com código de coleção, ano, preço e raridade como mini-objetos selecionáveis; selo 'Preço de mercado: US$ 4.75'.
- Erros inline desenhados (caixa brass com 'Tentar novamente', caixa vermelha ao salvar) sem derrubar a folha.

#### Trade — nova proposta, seletor de itens, revisão e erro de envio

Captura: `docs/qa/ui-live/current/ux-pack-08-critical-overlays-web-mobile/ux_pack08_18_trade_review_exact_identity.png (também 17, 19)`

**Problemas**

- Troca de cartas é o momento mais visual possível (carta X por carta Y) e está desenhada como formulário: miniaturas de 36–44px (create_trade_screen.dart:606, 847, 883), chips 'CMM #396' / 'Non-foil', linha de texto 'NM • PT-BR • R$ 22.00'. O layout não dá espaço para a arte.
- 'Revisar proposta' é um AlertDialog (create_trade_screen.dart:426) com dois parágrafos + caixa de aviso de 6 linhas ANTES de mostrar os itens — parede de texto; o resumo de valor é frase corrida ('Diferença: R$ 4.00 (18.2%) a favor do pedido') em vez de uma balança/numeral.
- Tela base: cabeçalhos de seção em sans, botões contornados 'Adicionar item', textarea 'Mensagem (opcional)', caixa de aviso, caixa de erro, botão largo 'Enviar Proposta' — pilha vertical de caixas de 1px.
- Seletor 'Meus itens para oferecer' é bottom sheet com linha de lista e ícone '+'.
- Aviso legal 'Combinação entre jogadores' aparece duas vezes (na tela e de novo na revisão).

**Acertos**

- Usa arte real e identidade exata da impressão (coleção, número, foil, idioma) — informação correta.
- Erro de envio inline com 'Tentar novamente' preserva o rascunho.
- Azul para 'ofereço' vs brass para 'quero' é um começo de cor com significado.

#### Login

Captura: `app/test/ui/goldens/runtime/web_mobile/login_empty.png`

**Problemas**

- Porta de entrada de um app de Magic sem nenhum sinal de Magic: fundo é o home_hero.png a 34% de opacidade sob véu de até 94% (auth_visual_shell.dart:30-54) — sobra um contorno abstrato. Sem arte, sem mana, sem mesa viva.
- Subtítulo burocrático: 'Acesse sua conta e acompanhe a disponibilidade da beta' — não vende nada.
- Dois campos chapados dentro de caixa surfaceElevated com borda 1px (AuthFormSurface, auth_visual_shell.dart:203-219; TextFormField em login_screen.dart:146 e 174). Correto, genérico.
- Terço inferior da tela vazio.

**Acertos**

- Logo com halo brass, 'BrewTact' em Fraunces, botão 'Entrar' com primaryGradient dourado e sombra brilhante (login_screen.dart:248-258) — há material e herói claros.
- Formulário mínimo (2 campos) é aceitável para login; respiro bom.

#### Cadastro (vazio e erro de consentimento)

Captura: `app/test/ui/goldens/runtime/web_mobile/register_empty.png (também register_consent_error.png)`

**Problemas**

- Quatro TextFormField empilhados (register_screen.dart:181, 214, 248, 296) + textos de ajuda + bloco de consentimento com CheckboxListTile (519) + dois OutlinedButton largos 'Ler Termos' / 'Ler Privacidade' (654) + linha de versões. É a definição de 'campos de texto empilhados'.
- O bloco de consentimento sozinho ocupa ~215px: o breakpoint interno é maxWidth < 360 (register_screen.dart:573), e como a largura útil dentro do cartão num telefone de 390 é ~326, os dois botões SEMPRE empilham no mobile.
- Consequência: o CTA dourado 'Criar conta' fica cortado na dobra em 844px — o herói da tela não aparece inteiro na primeira vista.
- 'Versões 2026-08-05 / 2026-07-21' é metadado de auditoria exposto ao usuário final.
- Nenhum elemento MTG; primeira experiência do produto é um formulário longo.

**Acertos**

- Estado de erro do consentimento é desenhado (borda vermelha no bloco + mensagem em negrito, live region).
- Cabeçalho com logo + 'Criar conta' serifado mantém a marca.
- Botão primário mantém o gradiente dourado do login.

#### Planos / Checkout / Upgrade (Beta gratuita)

Captura: `app/test/ui/goldens/runtime/web_mobile/plans_success.png (checkout_success.png e upgrade_success.png têm o MESMO md5 — /checkout e /upgrade redirecionam para /plans em release_capabilities.dart:514-517)`

**Problemas**

- Parede de texto jurídico-operacional: título 'Beta controlada, gratuita e sem cobrança' + parágrafo + 4 chips + divisor + outro parágrafo ('Não há assinatura, checkout, renovação, anúncio ou paywall…', free_beta_notice.dart:110). A tela inteira existe para dizer 'é grátis' e gasta ~90 palavras.
- Sopa de chips: Wrap de _BetaCapability (free_beta_notice.dart:88-95), caixas chapadas surfaceElevated com contorno outlineMuted de 1px (130-139), com rótulos de engenharia — 'Disponibilidade pelo servidor', 'Teto operacional, não comercial', 'IA revisável quando liberada'.
- O único dado real (120 ações de IA/mês) é uma LinearProgressIndicator de 8px com '0%' em labelSmall e a frase '0 de 120 usadas · 120 disponíveis em 2026-09.' (ai_usage_meter.dart:83-117). No contador isso seria um '120' serifado gigante dentro de um tile.
- heroGradient (free_beta_notice.dart:31) é imperceptível na captura; lê como caixa escura com borda brass de 1px.
- Sem ação primária, sem ponto focal, sem ilustração, zero MTG.
- Checkout e Upgrade não têm tela própria capturada: as três capturas são byte-idênticas.

**Acertos**

- Pílula 'Beta gratuita' em brass e título em Fraunces.
- Honestidade do conteúdo (não promete o que não existe).

#### Legal — Termos e privacidade

Captura: `app/test/ui/goldens/runtime/web_mobile/legal_terms.png (também legal_success.png, legal_privacy.png)`

**Problemas**

- Navegação entre documentos feita com dois botões largos empilhados 'Termos' (preenchido) / 'Privacidade' (contornado) — legal_screen.dart:347 — funcionam como abas mas parecem dois CTAs.
- Seções repetem o padrão caixinha de ícone 36px + título + bloco de texto + Divider (legal_screen.dart:458-498), igual ao perfil.
- Corpo em peso alto e cinza: massa de texto densa; sem medida de leitura editorial, sem sumário, sem capitular.
- Texto legal com jargão interno: 'Nesta revisão all-OFF', 'capability correspondente estiver liberada' — linguagem de flag de release num documento para o usuário.
- legal_privacy.png: uma seção de 6 linhas e ~600px de preto vazio.

**Acertos**

- Cabeçalho com escudo, título display, versões e a caixa 'Status do documento' são claros.
- Texto legal é texto — aqui o formato longo é legítimo; o problema é acabamento, não conceito.

#### Verificar email (deslogado)

Captura: `app/test/ui/goldens/runtime/web_mobile/verify_email_signed_out.png`

**Problemas**

- A única ação é um TextButton 'Entrar' (verify_email_screen.dart:232) dentro de uma caixa com uma frase solta (197-199) — a ação primária é o elemento mais fraco da tela.
- Carregando = CircularProgressIndicator cru (verify_email_screen.dart:170-176); mensagem e erro são Text simples (177-195). Não reaproveita o AppStatePanel.
- Nenhuma ilustração de email/envelope, nada de MTG.

**Acertos**

- Composição centrada com logo, título Fraunces grande e fundo com o hero da marca — mesma casca do login, coerente.
- Pouco texto, muito respiro.

### Cheiros de formulário (arquivo:linha)

- `app/lib/features/profile/profile_screen.dart:2293` — _ProfileSectionPanel: hairline no topo + caixinha de ícone 36px + título + subtítulo + conteúdo. É o molde de 'seção de Configurações' que estrutura a tela inteira.
- `app/lib/features/profile/profile_screen.dart:1186` — TextField 'Nick / Apelido' como único conteúdo de uma seção inteira; campo de formulário padrão com label flutuante.
- `app/lib/features/profile/profile_screen.dart:1402` — Wrap de OutlinedButton.icon 'Trocar senha' + TextButton.icon 'Encerrar outras sessões' — botões contornados de 1px com larguras arbitrárias alinhados à esquerda.
- `app/lib/features/profile/profile_screen.dart:1489` — Wrap de OutlinedButton 'Contas bloqueadas' / 'Exportar meus dados' + TextButton vermelho 'Excluir minha conta' (1518): lista de ações de conta estilo settings.
- `app/lib/features/profile/profile_screen.dart:1594` — _IdentityDestination: linhas rotuladas ícone + texto + seta ('Beta e política de uso', 'Legal e privacidade') — linha de menu de configurações.
- `app/lib/features/profile/profile_screen.dart:1547` — _IdentityBadge: pílulas de texto com contorno de 1px para estado ('Perfil não publicado', 'Email verificado') — estado em chip, não no objeto.
- `app/lib/features/profile/profile_screen.dart:1066` — CircleAvatar com a inicial do nome como herói do perfil — placeholder genérico, sem arte de carta.
- `app/lib/features/profile/profile_screen.dart:1696` — _VisibilityField = DropdownButtonFormField; _buildVisibilityGrid (1300-1383) empilha até 6 deles + dropdown de Estado (1234) + TextField cidade (1247) + textarea (1283) quando as capabilities forem liberadas.
- `app/lib/features/profile/profile_screen.dart:854` — Barra inferior permanente com FilledButton full-width 'Salvar alterações' (cinza desabilitado na maior parte do tempo) sobre Material chapado com hairline (870-882).
- `app/lib/features/profile/profile_screen.dart:1803` — _AvatarUrlDialog: AlertDialog com TextFormField 'URL da imagem' para trocar a foto — formulário de desenvolvedor, sem galeria nem preview.
- `app/lib/features/profile/profile_screen.dart:1914` — _ChangePasswordDialog: AlertDialog com 3 TextFormField empilhados (1924, 1950, 1966) + caixa de dica.
- `app/lib/features/profile/profile_screen.dart:2100` — _DeleteAccountDialog: AlertDialog com parágrafo, link, instrução e 2 TextFormField (2134, 2148); _RevokeSessionsDialog em 2034 segue o mesmo molde.
- `app/lib/features/profile/profile_screen.dart:535` — Diálogo 'Contas bloqueadas': carregando = CircularProgressIndicator solto; erro = Text + TextButton (556-568); lista = ListTile só texto (631). Estados genéricos apesar de existir AppStatePanel.
- `app/lib/features/auth/screens/register_screen.dart:181` — Quatro TextFormField empilhados (181, 214, 248, 296) com textos de ajuda intercalados.
- `app/lib/features/auth/screens/register_screen.dart:519` — CheckboxListTile de consentimento dentro de caixa com contorno de 1px (508-513), seguido de dois OutlinedButton largos (654).
- `app/lib/features/auth/screens/register_screen.dart:573` — Breakpoint constraints.maxWidth < 360 faz 'Ler Termos'/'Ler Privacidade' empilharem sempre em telefone de 390 (largura interna ~326), empurrando o CTA 'Criar conta' para fora da dobra.
- `app/lib/features/auth/screens/verify_email_screen.dart:232` — Única ação do estado deslogado é um TextButton 'Entrar'; carregando é CircularProgressIndicator cru (170-176) e mensagens são Text simples.
- `app/lib/features/auth/widgets/auth_visual_shell.dart:203` — AuthFormSurface: caixa surfaceElevated chapada com borda brass 16% de 1px — o 'card de formulário' de todas as telas de auth.
- `app/lib/features/commercial/widgets/free_beta_notice.dart:88` — Wrap de _BetaCapability: sopa de 4 chips (caixa chapada + contorno outlineMuted 1px, 130-139) com rótulos de engenharia.
- `app/lib/features/commercial/widgets/free_beta_notice.dart:110` — Parágrafo jurídico fixo após Divider — segunda parede de texto dentro do mesmo cartão.
- `app/lib/features/commercial/widgets/ai_usage_meter.dart:98` — LinearProgressIndicator de 8px + '0%' em labelSmall + frase '0 de 120 usadas…' (110-117): o único dado numérico da tela tratado como linha de formulário, não como numeral display.
- `app/lib/features/commercial/screens/legal_screen.dart:347` — _LegalNavigationButton: OutlinedButton.icon largo e empilhado servindo de aba entre Termos e Privacidade.
- `app/lib/features/commercial/screens/legal_screen.dart:458` — _LegalDocumentSection: caixinha de ícone 36px + título + bloco de texto + Divider (498) — mesmo molde de seção de settings do perfil.
- `app/lib/features/binder/widgets/binder_item_editor.dart:1074` — Três SwitchListTile seguidos (1074, 1093, 1112: Foil / Disponível para troca / Disponível para venda).
- `app/lib/features/binder/widgets/binder_item_editor.dart:998` — Wrap de ChoiceChip para Condição (998-1002) e outro com 8 chips de Idioma (1036-1044) — sopa de chips; segmented Tenho/Quero em 878/930; textarea Notas em 1176; AlertDialog cru de remoção em 363.
- `app/lib/features/trades/screens/create_trade_screen.dart:426` — 'Revisar proposta' como AlertDialog com dois parágrafos + caixa de aviso antes dos itens; miniaturas de carta de 36–44px (606, 847, 883); resumo de valor em frase corrida.
- `app/lib/features/decks/widgets/deck_commander_selector.dart:197` — Comandante selecionado como miniatura 48x67 em linha de lista, com TextButtons 'Remover'/'Trocar' (271).
- `app/lib/features/decks/screens/deck_list_screen.dart:1121` — Dialog 'Excluir deck?' (título sans em 1154) sem a arte do deck que está sendo excluído; inconsistente com os demais diálogos em Fraunces.
- `app/lib/features/social/screens/user_profile_screen.dart:632` — _StatItem: numerais 2/284/73 em sans pequeno; TabBar Material padrão em 579; miniaturas de deck 66x92 em linha de lista (820-823).

### Ganhos rápidos

- Medidor de IA: trocar a linha '0 de 120 usadas' + barra de 8px por numeral Fraunces gigante ('120' restantes) dentro de um tile com gradiente brass — mesma gramática do '40' do contador (ai_usage_meter.dart:71-117).
- Perfil público: aplicar displayFontFamily e escala grande nos numerais de _StatItem (user_profile_screen.dart:632); custo de uma linha de estilo.
- Cadastro: baixar o breakpoint de register_screen.dart:573 (ex.: < 300) para 'Ler Termos'/'Ler Privacidade' ficarem lado a lado em 390px, ou virar links inline no texto do checkbox — devolve o CTA 'Criar conta' para dentro da dobra. Remover a linha 'Versões 2026-08-05 / …' da vista do usuário.
- Diálogo 'Contas bloqueadas': substituir spinner cru e texto de erro (profile_screen.dart:528-573) pelo AppStatePanel que já existe; adicionar avatar nas linhas (631).
- Unificar tipografia dos overlays: título 'Excluir deck?' (deck_list_screen.dart:1154), 'Editar — Sol Ring' (binder_item_editor.dart:449) e AppBars 'Perfil'/'Estado da jornada' em Fraunces como os demais.
- Confirmação de exclusão de deck: incluir a miniatura/arte do comandante dentro do diálogo (deck_list_screen.dart:1121).
- Esconder a barra 'Salvar alterações' quando não há alterações (profile_screen.dart:870) — elimina o botão cinza permanente e o vazio acima dele; reduzir SizedBox space112 (1228).
- Limpar copy com jargão interno: 'capability liberada' (profile_screen.dart:1184), 'autorizados pelo servidor' (1173), 'superfícies de produto' (1217), 'Disponibilidade pelo servidor'/'Teto operacional, não comercial' (free_beta_notice.dart:20-22), 'revisão all-OFF' no texto legal, 'acompanhe a disponibilidade da beta' no login.
- AppStatePanel: subir a opacidade/escala da ilustração de órbitas e cartas (app_state_panel.dart:213), aumentar o título serifado (357) e centralizar verticalmente o bloco.
- Planos: cortar o texto pela metade e transformar os 4 chips em 2–4 tiles com ícone grande; elevar o contraste do heroGradient (free_beta_notice.dart:31) para o material aparecer.
- Seletor de comandante: aumentar a arte (deck_commander_selector.dart:197-198) para pelo menos 96x134 e usar art-crop como fundo do cartão.

### Redesenhos necessários

- Perfil próprio como 'mesa do jogador' em grade de tiles, não página de Configurações: tile-herói de identidade com arte de carta escolhida como avatar/fundo e identidade de cor em pips; tiles de numerais serifados (decks, partidas, vitórias, coleção); tiles de estado com o estado dentro do objeto (email verificado = tile verde com selo; perfil privado = tile tracejado 'não publicado', como INICIATIVA 'sem dono'); segurança e dados como tiles de ação (Senha, Sessões, Bloqueados com contagem, Exportar, Excluir em tile vermelho) — tudo visível de uma vez, sem seções com hairline.
- Substituir toda a família de AlertDialog+TextFormField do perfil (senha, sessões, excluir conta, avatar — profile_screen.dart:1803-2200) por superfícies próprias sobre a tela escurecida, no vocabulário do hub do contador; exclusão de conta como fluxo desenhado em passos, não modal com dois campos vermelhos.
- Seletor de avatar visual: grade de artes de carta (art-crop via Scryfall/CachedCardImage), comandantes dos próprios decks e upload de foto — eliminar o campo 'URL da imagem'.
- Privacidade/visibilidade (hoje 6 dropdowns em profile_screen.dart:1300-1383): redesenhar ANTES de liberar as capabilities, como tiles de três estados com ícone grande e cor (Público / Seguidores / Privado), estado dentro do tile.
- Planos/Beta: virar uma tela de um herói só — tile dourado 'BETA GRATUITA' com numeral '120' de ações de IA, 3–4 tiles de recurso com ícone/ilustração, e o jurídico rebaixado a um link. Dar a /checkout e /upgrade destino visual próprio ou removê-los (hoje são redirects para a mesma parede de texto).
- Casca de autenticação com identidade MTG: fundo com arte/mesa viva real (não o hero a 34% sob véu de 94%), símbolos de mana, e cadastro em 2 passos curtos (credenciais → consentimento) em vez de 4 campos + bloco de consentimento de 215px numa rolagem.
- Editor de carta do fichário: manter a arte-herói e o carrossel de edições, e redesenhar a metade de baixo — condição como régua visual NM→DMG, idioma como seletor compacto com bandeira/sigla única, Foil/Troca/Venda como três tiles alternáveis com ícone grande e cor (foil com brilho), quantidade como numeral display — eliminando switches e sopa de chips.
- Trade: composição 'mesa de troca' lado a lado — cartas grandes do que quero vs do que ofereço, balança de valor com numerais serifados e cor indicando para quem pende; revisão como tela/folha visual com as cartas em destaque e o aviso legal reduzido a uma linha.
- Legal: layout editorial de leitura (medida de linha, sumário por seções em tiles, peso de corpo regular, abas reais em vez de dois botões largos) e reescrita sem jargão de release.

### Contestação do revisor

A conclusão do auditor se mantém: esta área não está no nível do contador de vida. Nenhuma tela do núcleo (perfil, autenticação, planos, legal) usa a gramática do contador: azulejos como objetos, estado dentro do objeto, numerais Fraunces gigantes, material com profundidade. O auditor pesou um pouco a mão, e eu revejo a nota de 4 para cerca de 4,5 e o nível de "formulário" para "correto-genérico" baixo. Três telas seguem no nível "formulário" e pedem redesenho: Perfil próprio, Planos/Beta e o diálogo de foto por URL.

Abri a imagem de referência do contador e 27 capturas da área em 390px, e formei minha nota antes de reler a do auditor. Conferi 13 afirmações dele no código. Onze conferem com precisão de linha, e a parte factual do trabalho dele é sólida. Duas não conferem:

- **Painel de estado "não centralizado":** está centralizado. O código usa `Center` dentro de `minHeight` (`app_state_panel.dart:90-92`), e nas três capturas que medi as hairlines ficam simétricas em relação ao centro do corpo.
- **Nome truncado no perfil:** é fixture de estresse, com nomes de 45 a 50 caracteres postos de propósito nos testes. Com nome normal o cartão fica limpo, e isso não deveria ter custado ponto.

**Onde o auditor foi duro demais**
- Cadastro recebeu o rótulo "formulário", e trocar senha e excluir conta ficaram dentro da família de diálogos que ele também classificou como "formulário". Nesses casos formulário é a forma certa. O redesenho em passos que ele propõe adiciona fricção sem deixar a tela mais bonita.
- Ele aplicou objetos visuais 1 e identidade MTG 0 ou 1 a Legal e a telas de segurança. O critério não cabe ali e puxa a média para baixo.
- O nível "formulário" é mais duro que a própria planilha dele. A média das notas dá cerca de 2,5 de 5, e 9 das 15 linhas têm veredito "correto-genérico".
- Boa parte do pacote avaliado pertence a outras áreas: overlays de deck, fichário, trade e seletor de comandante. Esses itens não deveriam pesar na nota desta área.

**Onde ele foi generoso**
- Deu tipografia 4 para Login e Verificar email. É um único título serifado de cerca de 26px, sem contraste de escala nem numeral. Pela rubrica vale 3.

**O que ele acertou e eu reforço**
- A metade conta/segurança do Perfil próprio é uma página de Configurações pura. Ela fica na aba principal do app e não tem nenhum numeral nem elemento de Magic.
- Planos é uma parede de texto com chips de jargão interno e uma barra de 8px para o único número que importa (120).
- Trocar a foto colando uma URL é um formulário de desenvolvedor exposto ao usuário.
- O comandante aparece em miniatura de 48x67 e o trade usa miniaturas de cerca de 40px.
- Jargão interno ("capability", "all-OFF", "servidor") vaza na interface e no texto legal.
- O vazio "Primeiro deck" é a única tela boa do pacote, ainda abaixo do contador.

**O que ele perdeu**
- O mais grave é o contraste dos botões destrutivos. "Excluir definitivamente" e "Excluir deck" usam texto creme sobre salmão, com contraste medido de 1,99:1 contra o mínimo de 4,5:1 (`profile_screen.dart:2180-2182` e `deck_list_screen.dart:1202-1204`).
- A barra de salvar fica empilhada sobre a navegação inferior e ocupa cerca de 20% da tela do Perfil o tempo todo.
- O Perfil tem três níveis de título para um único campo de texto.
- Em Planos, "Beta gratuita" aparece três vezes nos primeiros 250px, e a frase do medidor mostra o período cru "2026-09".
- Há mistura de idioma e caixa entre telas: "Non-foil" no trade e "Sem foil" no fichário, "uncommon" e "Uncommon", "Enviar Proposta" e "Enviar proposta".
- O ganho rápido dele para o cadastro (botões lado a lado em 390px) truncaria "Ler Privacidade". Só a variante de links inline funciona.
- O switch ligado do fichário usa trilho marrom com polegar azul e não lê como ligado.

Os detalhes de cada ponto, com arquivo e linha, estão nos campos de discordâncias e de problemas perdidos.

**Discordâncias**

- **Painéis de estado (sem resultados, offline, indisponível, sessão expirada, permissão negada)** — auditor: Bloco não é centralizado verticalmente: ~230px vazios embaixo, duas hairlines soltas. · revisor: Erro factual. O bloco está centralizado: Center dentro de minHeight em app_state_panel.dart:90-92, e as hairlines são simétricas em relação ao centro do corpo nas três capturas que medi. Procedem a ilustração apagada, o título pequeno e o template único para os cinco estados. Essa família está acima do que o auditor descreve: é um sistema de estados desenhado, coerente e com cor semântica. Eu daria hierarquia 4, estados 4, primeiraImpressao 3, a mesma faixa dele, sem o demérito de composição.
- **Perfil próprio (topo) e Perfil público** — auditor: Nome serifado truncado em duas linhas dentro do cartão, listado como problema nas duas telas. · revisor: É artefato de fixture. Os nomes de 45–50 caracteres foram postos de propósito para estressar o layout. Com nome real o cartão de identidade fica limpo (pack 08, 'Guardião do Fichário'). O resto da crítica ao perfil próprio procede: avatar de inicial, pílulas de status, linhas ícone+texto+seta, zero numeral e zero MTG. O veredito 'correto-genérico' para o topo e 'formulário' para a metade conta/segurança está justo.
- **Cadastro** — auditor: Veredito 'formulario', objetosVisuais 1, e redesenho proposto em 2 passos (credenciais → consentimento). · revisor: Duro demais na forma. Cadastro com 4 campos (usuário, email, senha, confirmar) é o formato certo. Quebrar em 2 passos adiciona fricção sem deixar a tela mais bonita. O defeito real é de layout: o bloco de consentimento de ~215px empurra o CTA dourado para fora da dobra (confirmado na captura, 'Criar conta' cortado em y≈810), e há a linha 'Versões 2026-08-05 / 2026-07-21'. Reclassifico como 'correto-genérico com bug de dobra'. A casca (logo com halo, Fraunces, botão com gradiente e glow) é a mesma do login, que ele avaliou como correto-genérico. O ganho rápido dele (breakpoint <300 com botões lado a lado) truncaria 'Ler Privacidade'. Só a variante de links inline funciona.
- **Diálogos do perfil (trocar senha, encerrar sessões, excluir conta)** — auditor: Veredito 'formulario', primeiraImpressao 1. Redesenho: substituir toda a família por superfícies próprias e fazer exclusão de conta 'em passos'. · revisor: Trocar senha (3 campos) e excluir conta (frase de confirmação + senha) são casos em que formulário é a forma certa por segurança. É o padrão da indústria, e nenhum usuário espera azulejos aqui. Punir com objetosVisuais 1 e identidadeMtg 0 aplica critério que não cabe. O que procede nessa família: (a) 'Alterar foto' por URL HTTPS é o verdadeiro ofensor, um formulário de desenvolvedor sem preview; (b) 'Contas bloqueadas' tem estados crus; (c) a composição Cancelar/Excluir definitivamente está quebrada em 390px. Eu separaria: avatar por URL = 'formulario/feio'; senha, sessões e exclusão = 'correto-genérico' com acabamento a corrigir.
- **Legal — Termos e privacidade** — auditor: material 1, objetosVisuais 1, identidadeMtg 1. · revisor: Ele mesmo reconhece que texto legal é texto, mas as notas puxam a média da área para baixo com critérios que não se aplicam. Visualmente a tela é das mais bem resolvidas do núcleo: títulos de seção em Fraunces, ícone em tile frost, entrelinha confortável e caixa 'Status do documento' clara. Eu daria tipografia 4, respiro 4, primeiraImpressao 3. O achado do jargão ('revisão all-OFF', 'capability') em documento para o usuário é excelente e é o defeito mais sério da tela. Os dois botões largos servindo de abas também procedem.
- **Trade — nova proposta / revisão** — auditor: Veredito 'formulario', primeiraImpressao 2. · revisor: Fica na fronteira. Eu colocaria 'correto-genérico' baixo: há arte real, chips de identidade com cor (frost = ofereço, brass = quero), preço em brass e um erro inline desenhado. A crítica central procede: miniaturas de 36–44px no momento mais visual do app, AlertDialog quase fullscreen (y=34..810) e resumo de valor em frase corrida. A proposta da 'mesa de troca' é boa. Discordo só do rótulo, não do diagnóstico.
- **Login e Verificar email** — auditor: tipografia 4 nas duas. · revisor: Generoso neste ponto. É um único título Fraunces de ~26px sobre corpo sans, sem contraste de escala real nem numeral. Pela rubrica isso vale 3. O resto da leitura do login (herói claro no botão com gradiente, forma legítima, sem sinal de Magic, subtítulo burocrático) está justa.
- **Nota e nível da área** — auditor: notaArea 4/10, nivelArea 'formulario'. · revisor: A média aritmética das notas dele dá ~2,5/5 (5,0/10), e 9 das 15 linhas têm veredito 'correto-genérico'. O nível 'formulario' é mais duro que a própria planilha. Descontados o artefato de fixture, o erro de centralização e os critérios que não cabem em login, cadastro, legal e diálogos de segurança, a área fica em ~4,5–5/10, nível 'correto-genérico' baixo. Dentro dela há três ofensores de nível 'formulario' que precisam de redesenho: Perfil próprio (aba principal), Planos/Beta e o diálogo de avatar por URL. Boa parte do pacote avaliado (overlays de deck, fichário, trade, seletor de comandante, vazio 'Primeiro deck') pertence a outras áreas e não deveria pesar aqui nem para cima nem para baixo. A resposta ao dono não muda: não está no nível do contador.

**Problemas que o auditor perdeu**

- Contraste reprovado nos botões destrutivos preenchidos. 'Excluir definitivamente' (app/lib/features/profile/profile_screen.dart:2180-2182) e 'Excluir deck' (app/lib/features/decks/screens/deck_list_screen.dart:1202-1204) usam backgroundColor AppTheme.error (0xFFFF8A80, salmão claro) com foregroundColor AppTheme.textPrimary (creme 243,239,227). Medi nos PNGs: 1,99:1, muito abaixo de 4,5:1. O auditor viu o 'rosa-claro', mas não que o texto é quase ilegível justamente na ação mais perigosa do app.
- Cromo fixo empilhado no Perfil. A barra de salvar (~90px) fica sobre a bottom nav (~80px), somando ~170px (20% de um viewport de 844px) permanentemente ocupados por 'Tudo salvo' e um botão morto. O auditor citou o botão cinza, mas não o custo de área útil na aba principal.
- Três níveis de título para um único campo de texto no Perfil: eyebrow 'IDENTIDADE DE JOGADOR', depois H1 'Seu perfil e sua conta' com parágrafo, depois seção 'Como você aparece' com subtítulo, depois o label 'Nick / Apelido'. A hierarquia está inflada, com mais cabeçalho que conteúdo.
- A aba 'Perfil' é um dos 4 destinos principais da bottom nav e a primeira dobra não mostra nada do jogador (decks, partidas do contador, coleção). O auditor disse 'nenhum numeral', mas não enquadrou a gravidade: é uma aba primária cujo conteúdo é 100% configurações de conta. O problema é de arquitetura de informação, não só de acabamento.
- Redundância de copy em Planos: 'Beta gratuita' aparece 3 vezes nos primeiros 250px (AppBar, título do medidor, pílula), mais o título 'Beta controlada, gratuita e sem cobrança'. Abaixo da dobra ainda vem outra caixa verde 'Teto operacional sincronizado com o…'. O periodKey cru '2026-09' é interpolado na frase do medidor (app/lib/features/commercial/widgets/ai_usage_meter.dart:110-112).
- Mistura de idioma e caixa nas superfícies de carta: 'Non-foil' no trade contra 'Sem foil' no fichário; 'uncommon' minúsculo em inglês no carrossel de edições contra 'Uncommon' na linha de metadados; 'Enviar Proposta' na tela contra 'Enviar proposta' no diálogo.
- No editor do fichário, o switch ligado ('Disponível para troca') usa trilho marrom/brass escuro com polegar frost azul. A combinação é lamacenta, não lê como 'ligado' e destoa do resto da paleta (captura ux_pack08_16).
- Os títulos de AppBar são inconsistentes em toda a área, não só em 'Perfil'. 'Perfil' (próprio) e 'Meus Decks' estão em Fraunces. 'Perfil' (público), 'Beta gratuita', 'Termos e privacidade', 'Nova Proposta', 'Estado da jornada' e 'Perfil público' estão em sans. Falta uma regra única.
- No harness de estados, o estado 'Sem resultados' oferece a ação 'Tentar novamente' (visual_system_07), semanticamente errada para busca vazia (deveria ser limpar filtros). Pode ser artefato do harness 'Estado da jornada'. Vale conferir o uso real antes de punir.
- O ganho rápido do auditor para o cadastro (breakpoint <300 com botões lado a lado) causaria truncamento de 'Ler Privacidade' em ~149px por botão. A recomendação é tecnicamente falha, e a saída segura são links inline.

**Afirmações de código conferidas**

- ✅ profile_screen.dart:1066 — o herói do perfil é um CircleAvatar com a inicial do nome — CircleAvatar em app/lib/features/profile/profile_screen.dart:1068. O fundo é brass a 16% e o filho é a primeira letra quando não há URL. Se houver avatarUrl ele usa CachedNetworkImageProvider. Não existe caminho para usar arte de carta.
- ✅ profile_screen.dart:2293-2343 — _ProfileSectionPanel é hairline no topo + caixinha de ícone 36px + título Fraunces + subtítulo — Exato: Border(top: outlineMuted 0.74), Container 36x36 com brass a 10%, titleMedium com displayFontFamily w900, subtítulo bodySmall. É o molde de seção de Configurações.
- ✅ profile_screen.dart:854-882 — barra inferior permanente com FilledButton full-width desabilitado sobre Material chapado com hairline — SizedBox(width: compact ? double.infinity : 220) + FilledButton.icon com onPressed null quando !dirty. Fica sobre Material(color: surfaceSlate) com BorderSide strokeHairline no topo. Na captura visual_system_03 o botão vira dourado quando há alteração, então o problema é só o estado ocioso.
- ✅ register_screen.dart:573 — breakpoint maxWidth < 360 faz 'Ler Termos'/'Ler Privacidade' empilharem sempre em 390px — Confirmado no código. Na captura os botões vão de x=42 a x=348, 306px de largura útil, abaixo de 360, então empilha em qualquer telefone. O ganho rápido proposto (baixar para <300 e pôr lado a lado) dá ~149px por botão. 'Ler Privacidade' com ícone e padding precisa de ~170px e o label tem maxLines:1 com ellipsis (register_screen.dart:665), então truncaria. A alternativa que ele mesmo citou (links inline no texto do checkbox) é a correta.
- ✅ release_capabilities.dart:514-517 — /checkout e /upgrade redirecionam para /plans; as 3 capturas são byte-idênticas; ux_pack08_11 é idêntica à 08 — Redirect confirmado em app/lib/core/config/release_capabilities.dart:514-518. md5 d44590a35fb66968f11d2382a2b8adf7 nos três goldens. md5 db9821dafb921b3506c9211fd650dbe1 em ux_pack08_08 e ux_pack08_11.
- ✅ ai_usage_meter.dart:83-117 — o único dado numérico é LinearProgressIndicator de 8px + '0%' em labelSmall + frase corrida — minHeight: 8, porcentagem em labelSmall w800, frase em bodySmall. A frase interpola snapshot.periodKey cru ('2026-09'), um identificador de período exposto ao usuário. O auditor não apontou isso.
- ✅ free_beta_notice.dart:18-22, 31, 88-95, 110, 130-139 — sopa de 4 chips com rótulos de engenharia, heroGradient imperceptível, segundo parágrafo jurídico após o Divider — Tudo confere linha a linha. Na captura o cartão lê como caixa escura chapada com borda brass de 1px e o gradiente não aparece.
- ❌ AppStatePanel: 'Bloco não é centralizado verticalmente: ~230px vazios embaixo' — Falso. app/lib/core/widgets/app_state_panel.dart:90-92 usa SingleChildScrollView > ConstrainedBox(minHeight) > Center. Nas capturas as hairlines ficam em y=287/612 (no_results), 296/603 (offline) e 277/622 (permission_denied). Todas têm ponto médio 449,5, exatamente o centro do corpo (55..844). Há ~240px vazios em cima também, então o bloco está centralizado. Procedem as duas hairlines soltas e a ilustração com alpha 0,08–0,30 (linhas 244-275).
- ✅ deck_commander_selector.dart:197-198 — comandante selecionado é miniatura 48x67 — SizedBox(width: 48, height: 67) com CardArtwork(variant: recentDeck). CardArtwork embrulha CachedCardImage (app/lib/core/widgets/card_artwork.dart:262), então em produção é arte real. O problema é o tamanho dado pelo layout, não o fixture.
- ✅ binder_item_editor.dart:466 — arte-herói de ~180x252 — SizedBox 180x252 em 466-468 com CardArtwork(variant: gallery) e fallback ScryfallImageHelper.namedImageUrl. É arte real em produção.
- ✅ user_profile_screen.dart:632 (_StatItem com numerais sans pequenos) e 820-823 (CachedCardImage 66x92 em linha de lista) — Classe _StatItem em 632 com ícone 20px e TextStyle const sem displayFontFamily. CachedCardImage 66x92 em 820-825. Procede.
- ✅ profile_screen.dart:1696 / 1300-1383 — até 6 DropdownButtonFormField de visibilidade + dropdown de Estado quando as capabilities forem liberadas — 6 usos de _VisibilityField (1303, 1311, 1319, 1331, 1343, 1354) e DropdownButtonFormField em 1234 e 1696. É dívida latente, não visível hoje. O alerta de redesenhar antes de liberar está correto.
- ❌ Nome serifado truncado ('Marina — Arquivista de Co…', 'Aurora — Pilota Azorius e organiza…') tratado como defeito do design — É fixture de estresse deliberado. Os display_name têm 45–50 caracteres em app/test/features/profile/profile_screen_test.dart:34 e app/test/features/social/screens/user_profile_screen_responsive_test.dart:18. Com nome normal ('Guardião do Fichário', pack 08) não há truncamento. Elipse em duas linhas para um nome de 50 caracteres é comportamento correto, e não deveria ter custado ponto.

## Battle: coach, mesa ao vivo, jogar vs IA, replay, pós-jogo

**Auditor 3.5 → revisor 4.5** · formulário · auditor foi *justo*

Resposta direta: não. A área Battle não está no nível do contador; está a uns 3,5/10 dessa régua, e a distância não é de acabamento, é de gramática. O contador foi desenhado como objeto (azulejos, numerais serifados gigantes, estado dentro do objeto, material com gradiente). O Battle foi construído como engenharia de interface: o cuidado existe, mas foi todo para robustez — estados de reconexão, halos de foco por teclado, Semantics, chaves de teste, preflight — e quase nada para beleza.

Os números do código confirmam o que o olho vê: em ~10,9 mil linhas de telas do Battle o estilo display Fraunces aparece 3 vezes; o espectador ao vivo (1.736 linhas) tem zero gradientes e zero sombras; o Battle Lab (6.178 linhas) tem 2 ocorrências de gradiente/sombra contra dezenas de AlertDialog, TextField, DropdownButtonFormField, ExpansionTile, SegmentedButton e Slider. A vida do jogador, que no contador é um numeral enorme, aqui é uma pílula de 14px ('♥ 26') ou um chip 'Vida 40'.

Por tela: a mesa do Coach/Jogar vs IA é 'correto-genérico' e é o melhor ponto — arte real via CachedCardImage, brilho dourado na carta com ação legal, carta virada rotacionada; mas o painel de decisão é lista de linhas com chevron, tudo é caixa chapada com 1px e no desktop as cartas ficam minúsculas ao lado de um vazio enorme. O que cerca a mesa é formulário: o seletor de adversário é um AlertDialog com campo de busca, ListTile com rádio e campo de UUID, sem nenhuma arte (o modelo nem carrega imagem); o espectador ao vivo é sopa de chips em caixas aninhadas; o Battle Lab/replay é uma pilha de painéis de texto e ExpansionTiles com seis caixas cinzas 'Zona não observada' e erros como 'Mao'/'Exilio'; o pós-jogo é literalmente um formulário 'Registrar partida' com três TextFields. O fim de partida — o momento emocional — é um check verde com 'Partida concluída' escrito três vezes.

Há prova de que o time sabe fazer: o seletor de cartas do pós-jogo (azulejos com arte e borda verde/dourada de estado), o herói dourado do pós-jogo e o estado vazio do Battle Lab com motivo de campo de batalha já falam a língua do contador. O caminho é levar essa língua para o resto: ganhos rápidos (vida em numeral Fraunces, corrigir hierarquia do diálogo de concessão, cortar jargão e redundâncias, gradiente de vitória) sobem a área para ~5; chegar ao nível do contador exige redesenhar seletor de adversário, Battle Lab/replay, espectador e pós-jogo em torno de uma única 'mesa' desenhada e de azulejos em vez de formulários. Todas as 33 capturas listadas existiam e foram vistas; arte de fixture (Android/pós-jogo) não foi penalizada, pois em produção a arte é real.

- **Melhor tela:** Battle Coach — mesa ativa (docs/qa/ui-live/current/battle-coach-android/battle_coach_01_active_table.png): única tela onde a carta é protagonista e o estado mora no objeto (brilho dourado de ação legal, rotação de virada, selo de dano). Menção: o seletor de cartas do Pós-jogo (azulejos com borda verde/dourada) e o estado vazio do Battle Lab.
- **Pior tela:** Battle Lab — detalhe de replay (battle_learning_06_replay_evidence.png / play-vs-ai-web-real/08-replay.png): pilha de painéis de texto, ExpansionTiles, SegmentedButton, Slider e seis caixas cinzas 'Zona não observada', sem uma carta na tela. Logo atrás: o seletor de adversário (01-opponent-picker.png), um AlertDialog com TextField, ListTile+rádio e campo de UUID.

### Notas por tela

| Tela | Obj | Hier | Tipo | Mat | MTG | Resp | Est | 1ªimp | Média | Veredito |
|---|---|---|---|---|---|---|---|---|---|---|
| Entrada 'Jogar agora' — sheet 'Qual partida você vai abrir?' | 2 | 3 | 3 | 2 | 3 | 3 | 3 | 2 | 2.6 | correto, genérico |
| Battle Coach — boas-vindas | 2 | 4 | 4 | 3 | 2 | 2 | 3 | 3 | 2.9 | correto, genérico |
| Battle Coach — mesa ativa com decisão (mobile Android) | 4 | 3 | 2 | 2 | 4 | 3 | 3 | 3 | 3.0 | correto, genérico |
| Battle Coach — confirmação de concessão | 1 | 2 | 3 | 2 | 1 | 4 | 3 | 2 | 2.2 | formulário |
| Battle Coach — fim de partida (terminal) | 2 | 3 | 2 | 2 | 3 | 3 | 2 | 2 | 2.4 | correto, genérico |
| Jogar contra IA — mesa no desktop web | 3 | 3 | 2 | 2 | 4 | 2 | 3 | 3 | 2.8 | correto, genérico |
| Seletor de adversário (Jogar contra IA / Simular) | 1 | 2 | 3 | 1 | 1 | 2 | 2 | 1 | 1.6 | formulário |
| Acompanhar ao vivo (mesa do espectador) | 2 | 2 | 2 | 1 | 3 | 2 | 2 | 2 | 2.0 | formulário |
| Battle Lab — detalhe de replay / evidência | 1 | 2 | 1 | 2 | 1 | 1 | 3 | 1 | 1.5 | formulário |
| Battle Lab — vazio (nenhum replay) | 2 | 3 | 3 | 3 | 2 | 3 | 4 | 3 | 2.9 | correto, genérico |
| Pós-jogo (registrar partida, sinais de cartas, recibo) | 3 | 2 | 3 | 3 | 4 | 2 | 2 | 2 | 2.6 | formulário |
| Diálogo de sugestões com evidência de Battle (Optimize) | 2 | 2 | 3 | 2 | 2 | 2 | 2 | 2 | 2.1 | formulário |

#### Entrada 'Jogar agora' — sheet 'Qual partida você vai abrir?'

Captura: `docs/qa/ui-live/current/ux-pack-04-battle-learning-web-mobile/battle_learning_00_play_entry.png (e battle_learning_01_active_session.png)`

**Problemas**

- É um modal bottom sheet (app/lib/features/home/home_screen.dart:132) com linha de lista + chevron e um botão outlined largo — exatamente a gramática 'configurações' que o dono rejeita; a escolha de deck não é um azulejo, é uma linha.
- A arte do comandante aparece como miniatura de ~36px espremida à esquerda; o layout não dá protagonismo à arte.
- 'Nova partida rápida · sem deck' é um botão contornado de largura total com 1px de borda — sem material, sem peso.
- O cartão 'SESSÃO PAUSADA' tem tom dourado (bom), mas dentro dele há botão cheio + botão de texto empilhados e o texto de fixture 'Revisão aaaaaaaa preservada' expõe linguagem técnica.

**Acertos**

- Título em Fraunces com glifo próprio dá um mínimo de identidade.
- Estado 'sessão pausada' mora num cartão com cor com significado (dourado) — é o único objeto com estado da tela.

#### Battle Coach — boas-vindas

Captura: `docs/qa/ui-live/current/battle-coach-android/battle_coach_00_welcome.png`

**Problemas**

- O herói é um cartão de texto: ícone genérico de 68px + parágrafo centralizado de 6 linhas ('Durante o Alpha, o motor conduz...') — parede de texto onde deveria haver uma mesa/cartas (battle_coach_screen.dart:780-789).
- Colisão visual real: o rótulo 'MÃO · PILHA · CAMPO · DECISÕES COMPATÍVEIS' fica em cima do traço interno do motivo 'battlefield', e os pontos do motivo atravessam o parágrafo (ManaLoomThemeMotif em battle_coach_screen.dart:738-741 com intensidade 0.20 — fraco demais para ser material, forte o bastante para sujar o texto).
- Nenhuma arte de carta nem o comandante do deck do usuário: tela de entrada de um modo de JOGO sem um único objeto de Magic.
- Os dois '_CoachTrustChip' (battle_coach_screen.dart:793-801) são pílulas contornadas de largura total — leem como campos desabilitados.
- Metade da altura útil da tela fica vazia acima e abaixo do cartão.

**Acertos**

- Tem um herói único com heroGradient e borda dourada, título em Fraunces e uma única ação primária dourada — hierarquia clara.
- Estados de 'verificando mesa ativa' / erro de sessões estão previstos dentro do próprio herói.

#### Battle Coach — mesa ativa com decisão (mobile Android)

Captura: `docs/qa/ui-live/current/battle-coach-android/battle_coach_01_active_table.png (e 02_decision_prompt, 03_recoverable_error, 05_action_progress)`

**Problemas**

- O painel de decisão é uma pilha de linhas com chevron ('Conjurar Swan Song >', 'Passar prioridade >') + botão outlined largo 'Delegar esta decisão ao motor' + nota de rodapé: gramática de tela de ajustes (_PromptOptionTile, battle_coach_screen.dart:2460-2525; painel chapado com borda 1px em 2310-2314).
- Vida do jogador — o número mais importante de Magic — é uma pílula de 14px em labelSmall ('♥ 26') (_BoardBadge, battle_coach_screen.dart:2178-2222; uso em 1352-1359). No contador o mesmo dado é um numeral serifado enorme. Zero uso de Fraunces nesta tela.
- 'Sua prioridade' aparece duas vezes coladas (barra de status + título do painel); faixa ALPHA + barra de status + AppBar consomem ~20% da tela antes do conteúdo.
- O painel de decisão ocupa a primeira dobra inteira e empurra a mesa (o que é bonito) para baixo; em 05_action_progress sobra um buraco vazio de ~250px.
- A carta virada (rotação 0.25 em battle_coach_screen.dart:1758-1769) vaza para fora da margem esquerda do painel e encosta na carta vizinha — a zona não reserva largura para carta virada.
- Superfícies: tudo surfaceElevated chapado com contorno 1px; a mesa não tem 'feltro', profundidade nem gradiente.

**Acertos**

- Único lugar da área onde o objeto de Magic é protagonista: cartas em tamanho legível, rotação de virada animada, selo de dano sobre a arte, e ação legal marcada com borda + brilho dourado na própria carta (battle_coach_screen.dart:1830-1846) — o estado mora no objeto, como no contador.
- Arte: nas capturas Android a arte é de fixture (ilustração gerada); em produção é arte real via CachedCardImage(card.effectiveImageUrl) (battle_coach_screen.dart:1761) — confirmado pelas capturas play-vs-ai-web-real com scans reais do Scryfall.
- Banner de erro recuperável vermelho e barra de progresso de ação existem e são legíveis; relógio de 60s muda de cor quando urgente.

#### Battle Coach — confirmação de concessão

Captura: `docs/qa/ui-live/current/battle-coach-android/battle_coach_04_concede_confirmation.png`

**Problemas**

- AlertDialog padrão do Material (battle_coach_screen.dart:318-340): título, parágrafo, dois botões. O contador resolve o equivalente com azulejo 'ENCERRAR PARTIDA' dentro do hub, sem modal.
- Hierarquia invertida: a ação destrutiva 'Conceder' é o botão dourado cheio (FilledButton em :333) e 'Continuar jogando' é texto — o herói visual é a ação que o usuário menos deveria tocar por engano.
- Texto fala de 'motor conseguir salvá-lo' — linguagem de engenharia.

**Acertos**

- Título em Fraunces e bom respiro interno; o scrim escurece a mesa corretamente.

#### Battle Coach — fim de partida (terminal)

Captura: `docs/qa/ui-live/current/battle-coach-android/battle_coach_06_terminal_replay.png (e play-vs-ai-web-real/07-terminal-replay-rematch.png)`

**Problemas**

- O momento emocional do modo (ganhei/perdi) é um check verde de 38px + 'Partida concluída' escrito TRÊS vezes (barra de status, título, mensagem) + botão largo (_BattleCoachTerminalPanel, battle_coach_screen.dart:2712-2764; título em titleMedium sans em :2733).
- Não diz quem venceu de forma visual: nada de vida final 31 x 22 em numerais grandes, nada de arte do comandante vencedor, nenhum gradiente de vitória — e o tema já tem lifeCounterWinnerGradient (app_theme.dart:109) sem uso aqui.
- Na versão web o painel terminal fica num canto direito de 360px enquanto 60% da tela é vazio escuro; 'Sua mão está vazia' vira uma caixa cinza com texto.

**Acertos**

- Ação primária única e clara ('Analisar replay' / 'Jogar novamente').
- A mesa final continua visível abaixo com a arte das cartas.

#### Jogar contra IA — mesa no desktop web

Captura: `docs/qa/ui-live/current/play-vs-ai-web-real/02-private-hand-mulligan.png a 06-reconnected-session.png`

**Problemas**

- Em 1440px as permanentes no campo têm ~65px de largura (compact: true em battle_coach_screen.dart:1421) enquanto existe um vazio morto de ~200px de altura entre o campo e a mão: espaço sobrando e carta ilegível ao mesmo tempo.
- Estado vazio do campo é uma caixa contornada com 'Nenhuma permanente no campo' (battle_coach_screen.dart:1420) — caixa cinza com texto, duas vezes na tela de mulligan.
- Painel lateral de decisão = lista de linhas com chevron; rótulos crus do motor ('Plains — {T}: Add {W}.', 'Isamaru... — Cast Isamaru...') em vez de símbolo de mana e verbo em português.
- Vida/mão/grimório como três pílulas minúsculas no canto direito do cabeçalho do jogador; nenhum numeral expressivo.
- Nomes de deck de fixture ('QA Web Krenko 28383ebd086b') são artefato de captura, não do design.

**Acertos**

- Arte real do Scryfall, pré-visualização grande da carta ao passar o mouse, mão com brilho dourado nas cartas jogáveis, carta virada rotacionada — a base de uma mesa bonita existe.
- Faixa lateral dourada + selo 'Prioridade' no jogador ativo é cor com significado.

#### Seletor de adversário (Jogar contra IA / Simular)

Captura: `docs/qa/ui-live/current/play-vs-ai-web-real/01-opponent-picker.png (e 09-rematch-picker.png)`

**Problemas**

- É literalmente um formulário dentro de um AlertDialog (battle_replays_screen.dart:1544): TextField 'Buscar adversário' (:1577), ListTile com ícone genérico Icons.style_outlined e rádio à direita (:1868-1893), botão de texto 'Usar ID técnico' que abre um campo de UUID (:1609-1647), caixa de aviso e botão desabilitado.
- Escolher o rival é o momento mais 'visual' possível (arte do comandante, identidade de cor) e aqui não há arte nenhuma — e não é artefato de fixture: o modelo BattleOpponentDeck (battle_replay_service.dart:84-101) nem carrega URL de imagem ou identidade de cor, então em produção também não há arte.
- No modo simulação o mesmo diálogo ainda empilha DropdownButtonFormField 'O que você quer observar?' (:1651), TextField 'Cartas de foco' separadas por vírgula (:1676) e Dropdown 'Tamanho da amostra' (:1697) com parágrafo sobre 'seed e chave de idempotência' (:1720-1722).
- ~45% do diálogo é área vazia; estados vazio/erro/busca são texto centralizado cinza (:1814-1832).

**Acertos**

- Título em Fraunces. Funcionalmente completo (preflight, busca, teclado). Visualmente, nada a preservar.

#### Acompanhar ao vivo (mesa do espectador)

Captura: `docs/qa/ui-live/current/ux-pack-04-battle-learning-web-mobile/battle_learning_02_live_table.png a 05_completed.png; battle-live-web/battle_live_00_waiting.png a 04_completed_replay.png`

**Problemas**

- Sopa de chips como representação do jogador: 'Vida 40 · Mão 6 · Grimório 91 · Campo 1 · Cemitério 0 · Mana 1' — seis pílulas de texto por jogador (Wrap em battle_live_spectator_screen.dart:1028-1061; _PublicMetric em :1186-1218 renderiza literalmente '$label $value'). No web a 'mesa' inteira são dois blocos de chips.
- Caixas dentro de caixas dentro de caixas: tela > cartão 'Estado observável' > cartão do jogador (:1007-1016) > chips. Tudo surfaceElevated chapado com contorno 1px; o arquivo inteiro (1.736 linhas) tem ZERO gradientes e ZERO sombras.
- 'Pilha / Pilha vazia' e 'Combate / Sem combate declarado' são linhas de rótulo+valor em texto (_PublicZoneSummary, :1221-1252).
- Estado de espera = duas caixas cinzas com frase ('Aguardando o primeiro estado público da partida.' :930; 'A timeline aparecerá quando o motor publicar eventos.' :1300). Timeout e concluído usam o mesmo cartão com ícone azul — sem emoção nem diferenciação além do texto.
- Textos de engenharia na cara do usuário: 'Somente zonas públicas e contagens validadas são exibidas', 'Atalhos: Espaço pausa localmente · End volta ao mais recente · R reconecta' (:544), 'Replay persistido', 'Battle concluído e replay validado'.
- A barra fixa 'Somente acompanhamento — você não controla a partida' ocupa duas linhas permanentes no topo do mobile.

**Acertos**

- No mobile as cartas públicas aparecem como scan completo 72x101 via CardArtwork com URL exata por card_id (:1131-1166) — arte real em produção; o quadrado cinza com ícone só aparece para objeto sem impressão (ficha 'Pista criada por efeito'), o que é legítimo.
- Timeline com miniatura da carta conjurada e selo numérico colorido é o embrião de um feed visual.
- Banner de reconexão preserva o estado e tem cor de erro coerente.

#### Battle Lab — detalhe de replay / evidência

Captura: `docs/qa/ui-live/current/ux-pack-04-battle-learning-web-mobile/battle_learning_06_replay_evidence.png (e play-vs-ai-web-real/08-replay.png)`

**Problemas**

- A tela é uma pilha de painéis de texto: cabeçalho 'Escolha o tipo de teste' com parágrafo-disclaimer de 4 linhas + 3 botões empilhados (battle_replays_screen.dart:2337-2402), painel dourado 'Transformar replay em evidência do deck' com outro parágrafo, e uma sequência de ExpansionTile ('Execução concluída', 'Meu caderno de Battle', 'Dados técnicos' — :3236, :3461, :4225) mais 'Comparação descritiva' com mais um parágrafo e botão.
- Três CTAs dourados competindo na mesma dobra (Testar consistência, Registrar aprendizado, Usar como base): não há herói.
- Zero Fraunces no mobile; todos os títulos são Inter bold do mesmo tamanho. Em 6.178 linhas o arquivo usa estilo display uma única vez (:2204) e só 2 ocorrências de gradiente/sombra.
- O 'visualizador' de replay no web: SegmentedButton Replay/Decisões (:3060), Slider de etapa (:4567), chips de vida/mana ('40 vida', 'Mana —' via _ReplayMetaChip em :5058-5064) e SEIS caixas cinzas 'Zona não observada por este motor' / '0 cartas observados' (:5177-5201). Um replay de Magic sem uma carta na tela.
- Erros de acabamento visíveis: 'Mao' e 'Exilio' sem acento (:5078, :5107), 'Jogador snapshot', 'interactive_coach contra QA Web Krenko...' como título, 'Payload sanitizado para diagnóstico' exposto ao usuário.
- Lista de replays: cartão com 4 chips de metadados ('Cancelado', '4 turnos', '15 eventos', '26/08 08:34') e filtros em ExpansionTile + DropdownButtonFormField (:1164, :1255); anotações/reflexões/reportes abrem AlertDialogs com TextField e Dropdown (:5618, :5690, :5780).
- Arte: o carrossel _BattleVisualCardCarousel mostra arte real quando o motor observa as zonas; o vazio da captura é limite de dados do motor, não do fixture — mas o layout responde a isso desenhando seis caixas cinzas em vez de recolher a zona.

**Acertos**

- O painel de handoff tem tom dourado distinto dos demais (cor com significado).
- O conteúdo é rico (destaques, 'Eu faria diferente', curva de vida) — há matéria-prima para uma tela bonita; falta desenhá-la.

#### Battle Lab — vazio (nenhum replay)

Captura: `app/test/ui/goldens/runtime/web_mobile/battle_replays_empty.png`

**Problemas**

- Metade superior é o mesmo bloco-formulário: parágrafo de 5 linhas com disclaimer jurídico ('Nenhum modo prova superioridade ou substitui regra oficial') + 3 botões empilhados de larguras diferentes.
- 'Testar consistência' aparece duas vezes na mesma tela (outlined em cima, dourado embaixo) e ainda há 'Jogar contra IA' dourado — três chamadas, dois dourados.
- Os pontos do motivo atravessam o texto do estado vazio ('Cada replay informa o motor e o contrato de execução usados' — também é texto de engenharia).

**Acertos**

- O estado vazio é DESENHADO: esboço de campo de batalha ao fundo, medalhão com glifo, rótulo 'PRÓXIMO PASSO', título em Fraunces e CTA — é o melhor estado vazio da área e mostra que o time sabe fazer.

#### Pós-jogo (registrar partida, sinais de cartas, recibo)

Captura: `app/test/ui/goldens/runtime/web_mobile/post_game_empty.png; ux-pack-04-battle-learning-web-mobile/battle_learning_07_postgame_signals.png e 08_postgame_receipt.png`

**Problemas**

- O miolo chama-se 'Registrar partida' e é um formulário literal: três TextField empilhados — 'Resultado' (texto livre!), 'Nível da mesa' (texto livre para 4 opções fixas: casual/melhorada/otimizada/cEDH) e 'Notas' (app/lib/features/retention/screens/post_game_notes_screen.dart:1272, :1281, :1290), mais TextField de busca (:1425), FilterChips 'Problemas observados' (:1326) e botão de largura total 'Salvar pós-jogo' (:1339).
- A primeira coisa na tela é a caixa 'Evolução do deck · 0 jogos' com dois botões DESABILITADOS (Otimizar/Reconstruir) e dois parágrafos — o topo da tela é um painel morto; o herói dourado vem só depois.
- Recibo de sucesso: 'Evidência 17875852... salva localmente · 1 problema(s) · 2 carta(s)' — hash truncado e plural com parênteses num banner verde; o momento de recompensa é um log.
- Histórico vazio = caixa cinza com frase (:1700).
- Resultado da partida deveria ser o numeral/objeto herói (1º, 2º, derrota) e é um campo de texto com placeholder.

**Acertos**

- O seletor 'Cartas realmente observadas' é o melhor objeto visual da área: azulejos com arte da carta, e o estado mora no objeto — borda verde = preservar, borda dourada = revisar, com contadores coloridos abaixo (post_game_notes_screen.dart:1559-1650). Isso é gramática de contador.
- _PostGameSourceHero (:606-700) tem gradiente dourado, arte de carta em CardArtwork fullCard e nome do deck em Fraunces — material e identidade corretos. Arte de fixture nas capturas; em produção é a arte real do deck.

#### Diálogo de sugestões com evidência de Battle (Optimize)

Captura: `docs/qa/ui-live/current/ux-pack-04-battle-learning-web-mobile/battle_learning_09_optimize_evidence.png`

**Problemas**

- Modal com paredes de texto ('O registro foi reaberto pelo backend com o usuário e o deck autenticados...') — linguagem de auditoria, não de produto.
- Rodapé com três ações empilhadas e alinhadas à direita (Cancelar / Compartilhar relatório / Aplicar mudanças desabilitado): a ação primária é um botão cinza morto.
- Evidência de carta em miniatura de ~45px dentro de um carrossel que precisa de instrução escrita ('Deslize para conferir todas as evidências').
- Chips 'Velocidade' / 'Mana' soltos sem ícone nem cor.

**Acertos**

- Título em Fraunces com ícone; cartão 'PRESERVAR Sol Ring' com tom verde liga cor ao significado.

### Cheiros de formulário (arquivo:linha)

- `app/lib/features/battle/screens/battle_replays_screen.dart:1544` — Seletor de adversário inteiro dentro de um AlertDialog (título + parágrafo + campos + Cancelar/Confirmar).
- `app/lib/features/battle/screens/battle_replays_screen.dart:1577` — TextField 'Buscar adversário' com autofocus como primeiro elemento da escolha de rival.
- `app/lib/features/battle/screens/battle_replays_screen.dart:1629` — TextField de UUID ('Usar ID técnico', hint 00000000-0000-...) exposto ao usuário final.
- `app/lib/features/battle/screens/battle_replays_screen.dart:1651` — DropdownButtonFormField 'O que você quer observar?' + TextField 'Cartas de foco' separadas por vírgula (:1676) + Dropdown 'Tamanho da amostra' (:1697) com parágrafo sobre seed/idempotência (:1720).
- `app/lib/features/battle/screens/battle_replays_screen.dart:1868` — Deck adversário como ListTile com ícone genérico Icons.style_outlined e rádio à direita; o modelo BattleOpponentDeck (services/battle_replay_service.dart:84) nem tem campo de imagem.
- `app/lib/features/battle/screens/battle_replays_screen.dart:2337` — Cabeçalho 'Escolha o tipo de teste': parágrafo-disclaimer de 4-5 linhas + Wrap de OutlinedButton/FilledButton (:2364-2401) em vez de azulejos de modo.
- `app/lib/features/battle/screens/battle_replays_screen.dart:1164` — Filtros do histórico em ExpansionTile com DropdownButtonFormField (:1255).
- `app/lib/features/battle/screens/battle_replays_screen.dart:3060` — SegmentedButton 'Replay / Decisões' como navegação do detalhe.
- `app/lib/features/battle/screens/battle_replays_screen.dart:3236` — Pilha de ExpansionTile (relatório :3236, caderno :3461, dados técnicos :4225) — conteúdo aninhado e escondido, o oposto de 'tudo visível de uma vez'.
- `app/lib/features/battle/screens/battle_replays_screen.dart:4567` — Slider do Material como linha do tempo do replay; busca de eventos com TextField + Dropdown (:4090, :4100).
- `app/lib/features/battle/screens/battle_replays_screen.dart:5058` — Vida e mana do jogador como _ReplayMetaChip de texto ('40 vida', 'Mana —').
- `app/lib/features/battle/screens/battle_replays_screen.dart:5177` — Zona sem dados vira caixa cinza contornada com frase ('Zona não observada por este motor', '0 cartas observados') — seis por tela; rótulos 'Mao' (:5078) e 'Exilio' (:5107) sem acento.
- `app/lib/features/battle/screens/battle_replays_screen.dart:5618` — Notas, reflexões e reporte de evento em AlertDialogs com TextField/DropdownButtonFormField (:5618, :5690, :5780).
- `app/lib/features/battle/screens/battle_coach_screen.dart:320` — Concessão em AlertDialog padrão; a ação destrutiva é o FilledButton dourado (:333).
- `app/lib/features/battle/screens/battle_coach_screen.dart:2460` — _PromptOptionTile: opção de jogada como linha de lista com miniatura 45x63, rótulo e chevron — linha de configurações.
- `app/lib/features/battle/screens/battle_coach_screen.dart:2395` — OutlinedButton de largura total 'Deixar esta ação no automático' + nota de rodapé explicativa (:2404) em toda decisão.
- `app/lib/features/battle/screens/battle_coach_screen.dart:2556` — Decisão numérica com Slider + FilledButton 'Confirmar quantidade'; distribuição múltipla com TextField 'Ex.: 1 0 2 — separe por espaço' (:2624).
- `app/lib/features/battle/screens/battle_coach_screen.dart:2178` — _BoardBadge: vida/mão/grimório como pílulas de 14px em labelSmall; nenhum numeral display (uso em :1352-1375).
- `app/lib/features/battle/screens/battle_coach_screen.dart:2712` — Painel de fim de partida: caixa chapada com borda 1px, ícone 38px, título titleMedium sans (:2733) e botões largos; sem gradiente de vitória nem placar.
- `app/lib/features/battle/screens/battle_coach_screen.dart:793` — _CoachTrustChip: pílulas contornadas de largura total no herói de boas-vindas, leem como campos desabilitados.
- `app/lib/features/battle/screens/battle_live_spectator_screen.dart:1028` — Wrap com seis _PublicMetric por jogador — sopa de chips 'Vida 40 Mão 6 Grimório 91...' (_PublicMetric em :1186 renderiza '$label $value').
- `app/lib/features/battle/screens/battle_live_spectator_screen.dart:1221` — _PublicZoneSummary: Pilha e Combate como linhas rótulo/valor em texto ('Pilha vazia', 'Sem combate declarado').
- `app/lib/features/battle/screens/battle_live_spectator_screen.dart:1007` — Cartão do jogador chapado (surfaceElevated + borda 1px) aninhado dentro de outro cartão; arquivo inteiro sem um único gradiente ou sombra.
- `app/lib/features/battle/screens/battle_live_spectator_screen.dart:544` — Linha de texto com atalhos de teclado e jargão ('Pausar não interrompe o motor') no painel principal; estados vazios como frase em caixa cinza (:930, :1300).
- `app/lib/features/retention/screens/post_game_notes_screen.dart:1272` — Formulário 'Registrar partida': TextField Resultado (:1272), TextField Nível da mesa em texto livre (:1281), TextField Notas (:1290).
- `app/lib/features/retention/screens/post_game_notes_screen.dart:1326` — FilterChips 'Problemas observados' sem ícone/cor + ElevatedButton de largura total 'Salvar pós-jogo' (:1339); histórico vazio como frase em caixa (:1700).
- `app/lib/features/home/home_screen.dart:132` — Entrada 'Jogar agora' em showModalBottomSheet com linha de lista + chevron e OutlinedButton largo 'Nova partida rápida · sem deck' (:1029).

### Ganhos rápidos

- Vida como numeral Fraunces grande nas três mesas: trocar o _BoardBadge de vida (battle_coach_screen.dart:1352), o chip 'Vida' (battle_live_spectator_screen.dart:1032) e o _ReplayMetaChip (battle_replays_screen.dart:5058) por um numeral display com coração — maior ganho de identidade por linha alterada.
- Corrigir 'Mao' e 'Exilio' (battle_replays_screen.dart:5078, :5107) e tirar jargão visível: 'Jogador snapshot', 'Payload sanitizado', 'Replay persistido', 'motor', hash no recibo do pós-jogo.
- Concessão: tornar 'Continuar jogando' o botão dourado e 'Conceder' em cor de erro (battle_coach_screen.dart:328-336).
- Remover redundâncias: 'Sua prioridade' duplicado (barra + título do painel) e 'Partida concluída' triplicado no terminal.
- Fim de partida: título em headlineSmall (Fraunces), fundo com lifeCounterWinnerGradient (app_theme.dart:109) e placar final em numerais grandes no _BattleCoachTerminalPanel (battle_coach_screen.dart:2712-2764).
- Cabeçalho do Battle Lab: cortar o parágrafo-disclaimer para uma linha e eliminar o CTA duplicado 'Testar consistência' no estado vazio; deixar um único dourado por dobra.
- Espectador: esconder no mobile 'Somente zonas públicas...' e a linha de atalhos (battle_live_spectator_screen.dart:544); não renderizar 'Pilha vazia' / 'Sem combate declarado' quando vazios.
- Replay: recolher zonas sem dados em vez de desenhar caixa cinza por zona (battle_replays_screen.dart:5177-5201).
- Boas-vindas do Coach: corrigir a colisão do rótulo com o traço do motivo, reduzir o parágrafo para 2 linhas e trocar os _CoachTrustChip por ícones sem contorno.
- Desktop: aumentar as permanentes do campo (remover compact em battle_coach_screen.dart:1421 acima de ~900px) para ocupar o vazio central; reservar largura para carta virada para não vazar da margem.
- Pós-jogo: mover 'Evolução do deck' (com botões desabilitados) para baixo do herói dourado; trocar 'Nível da mesa' de TextField livre por 4 azulejos (Casual/Melhorada/Otimizada/cEDH).
- Esconder 'Usar ID técnico' do usuário final (flag de debug) no seletor de adversário.

### Redesenhos necessários

- Seletor de adversário como tela 'escolha seu rival': grade de azulejos com arte do comandante e identidade de cor, composição 'seu comandante × rival', estado de preflight dentro do azulejo — sem AlertDialog, sem ListTile/rádio. Exige incluir imagem/identidade de cor no payload de BattleOpponentDeck (battle_replay_service.dart:84).
- Battle Lab / replay redesenhado como a própria mesa: reaproveitar o tabuleiro do Coach como visualizador, linha do tempo por turnos com numerais serifados e miniaturas das cartas jogadas, modos de teste como 3 azulejos com glifo; desmontar a pilha de ExpansionTile em azulejos (relatório, caderno, comparação, técnico) visíveis de uma vez; notas/reflexões sem AlertDialog.
- Uma única 'mesa' desenhada para a área: hoje há três implementações diferentes e chapadas (_PlayerZone no coach, _BattleLivePlayer no espectador, _VisualPlayerBoard no replay). Criar um componente de mesa com material (feltro/gradiente, profundidade), vida em numeral display, zonas como objetos (pilha de cemitério, grimório com contagem) e usá-lo nos três lugares.
- Painel de decisão do Coach como bandeja de ações: cartas-objeto grandes tocáveis e um azulejo herói 'Passar prioridade' (como o PASSAR A VEZ do contador), em vez de linhas com chevron; decisões numéricas com stepper de numerais grandes no lugar de Slider e do TextField '1 0 2'.
- Espectador ao vivo: substituir o dashboard de chips pela mesa compartilhada + feed de eventos com arte; estados de espera/timeout/concluído com ilustração e cor próprios.
- Pós-jogo: resultado como escolha visual (azulejos Vitória / 2º / Derrota com numeral), seletor de cartas como protagonista da tela, problemas observados como azulejos com ícone e cor, histórico como azulejos de partida com resultado em numeral; recibo de salvamento como momento de recompensa e não como log.
- Momento de fim de partida (vitória/derrota) com arte do comandante, placar final e gradiente — hoje é um check verde numa caixa.

### Contestação do revisor

Veredito sobre o auditor: justo. A resposta dele à pergunta do dono se mantém: a área Battle não está no nível do contador, e a diferença é de gramática visual, não de acabamento. Abri a imagem de referência e 21 capturas da área antes de reler a avaliação dele. Entre elas estão a melhor tela (mesa do Coach), as piores (detalhe de replay no mobile e no web, seletor de adversário), boas-vindas, fim de partida, concessão, espectador no mobile e no web, pós-jogo vazio, com sinais e com recibo, estado vazio do Battle Lab, diálogo do Optimize, mulligan e combate no desktop. Minhas notas ficaram a no máximo 1 ponto das dele em quase todos os critérios. Conferi 11 afirmações de código; 8 batem linha a linha.

**Onde ele foi duro demais**
- Tratou a confirmação de concessão como "formulário" e puniu a falta de arte nela. Confirmar uma ação destrutiva em diálogo é legítimo, e o próprio contador usa AlertDialog para confirmações. O defeito real ali é o botão dourado na ação destrutiva e o texto de engenharia.
- A afirmação "sem cartas no web" no espectador vem do fixture, que só envia contagens. O código mostra scans reais quando as listas chegam.
- A nota 3,5/10 é mais baixa que a média das notas dele mesmo, que dá 2,39/5, ou 4,8/10.

**Onde ele foi generoso ou errou**
- Deu objetosVisuais=4 para a mesa do Coach no mobile. A primeira dobra é só painel de linhas com chevron; as cartas ficam abaixo dela.
- Incluiu no Battle a tela "Jogar agora", que é a porta do contador de vida.
- Recomendou o lifeCounterWinnerGradient, um token pastel que o app não usa em lugar nenhum e que destoa da paleta.
- As contagens de gradiente e de Fraunces estão ligeiramente erradas, sem alterar a conclusão.

**O que ele perdeu**
- As fases aparecem em inglês no espectador ("Main · Precombat"), embora o Coach já tenha o mapa em português.
- O widget ManaCostRow existe e quase não é usado no Battle; o custo aparece como "{T}: Add {W}" em texto cru.
- O CTA de fim de partida difere entre Android e web.
- O estado do jogador zera após a concessão.
- O pós-jogo volta como formulário vazio logo abaixo do recibo de sucesso.
- O banner fixo do espectador recorta o conteúdo que rola por baixo.

**Nota revisada: 4,5/10**, na mesma escala do "3,5/10" do auditor, o que equivale a cerca de 2,25/5 na rubrica. O nível continua "formulário": o hub Battle Lab, o seletor de adversário, o replay, o espectador e o registro do pós-jogo são superfícies de ajustes. A mesa do Coach é correto-genérica. Os azulejos de cartas do pós-jogo, o herói dourado e o estado vazio do Battle Lab mostram que o time sabe trabalhar no padrão do contador.

**Discordâncias**

- **Entrada 'Jogar agora' — sheet 'Qual partida você vai abrir?' (battle_learning_00/01)** — auditor: Avaliou como tela da área Battle (veredito correto-genérico, média ~2,6). · revisor: A crítica visual é correta, mas a tela não pertence ao Battle. Em app/lib/features/home/home_screen.dart:114-132 o sheet é protegido por _lifeCounterAllowed e carrega o LifeCounterSessionStore, ou seja, é a porta de entrada do contador de vida. Deve sair da média do Battle. Vale registrar na área Home/Contador que a porta do contador é um bottom sheet com linha e chevron.
- **Battle Coach — confirmação de concessão (battle_coach_04)** — auditor: Veredito 'formulario' com objetosVisuais=1 e identidadeMtg=1; afirma que o contador resolve o equivalente sem modal. · revisor: Duro demais. Confirmar uma ação destrutiva em diálogo é padrão legítimo, e o próprio contador usa AlertDialog para confirmações (life_counter_native_history_sheet.dart:367 e :413; life_counter_native_player_appearance_sheet.dart:737). Falta de arte num diálogo de duas linhas não deveria ser punida. O problema real aqui é outro: a hierarquia invertida, com 'Conceder' como FilledButton dourado em battle_coach_screen.dart:333, e o texto sobre 'motor conseguir salvá-lo'. Eu trataria como forma legítima com correção pontual, nota perto de 3, fora do balde 'formulário'.
- **Acompanhar ao vivo — versão web (battle_live_01_active_feed)** — auditor: "No web a 'mesa' inteira são dois blocos de chips." · revisor: Em parte é artefato do fixture. O teste app/integration_test/battle_live_visual_runtime_proof_test.dart:489-502 envia só 'battlefield_count' e nenhuma lista 'battlefield'. O código (battle_live_spectator_screen.dart:1063-1070) mostra as zonas com scan das cartas quando as listas chegam, e a captura mobile battle_learning_02 confirma isso. A sopa de seis chips por jogador, as caixas aninhadas e a ausência total de gradiente e sombra são reais, então material=1 e o veredito se mantêm. Só a afirmação 'sem cartas no web' não vale como prova de design.
- **Battle Coach — fim de partida (ganho rápido sugerido)** — auditor: Recomenda usar lifeCounterWinnerGradient (app_theme.dart:109), descrito como já existente e 'sem uso aqui'. · revisor: Recomendação ruim. Esse token é um arco-íris pastel (FF9CD1, FFF5A3, B7FFBE) e não é usado em nenhum lugar do app; o grep encontra só a definição. É um token morto e estranho à paleta dourado/azul-noite do contador atual. O diagnóstico está certo (fim de partida sem placar, sem arte e sem emoção), mas a solução deveria partir do heroGradient e do dourado, como no tile PASSAR A VEZ.
- **Battle Coach — mesa ativa mobile (battle_coach_01)** — auditor: objetosVisuais=4 e eleita a melhor tela. · revisor: Levemente generoso. No mobile, a primeira dobra mostra só faixa ALPHA, barra de status e o painel de linhas com chevron. As cartas começam por volta de 60% da altura, então a impressão em 1 segundo é de tela de ajustes; a mesa bonita fica abaixo da dobra. Eu daria objetosVisuais=3. Continua sendo a melhor tela da área, mas por falta de concorrência.
- **Nota geral da área** — auditor: notaArea 3,5 (no resumo, '3,5/10'). · revisor: O número não bate com a rubrica do próprio auditor. A média das 96 notas dele dá 2,39/5, o equivalente a 4,8/10. Sem a tela que não é Battle (entrada), com a concessão reclassificada e com meu ajuste na mesa mobile, chego a cerca de 2,25/5, ou 4,5/10. O nível 'formulário' se mantém. Metade das telas é formulário literal e todo o caminho obrigatório é superfície de ajustes: hub Battle Lab, seletor de adversário, replay e pós-jogo. A mesa do Coach é a única parte correto-genérica.
- **Métricas de código citadas no resumo** — auditor: "Battle Lab tem 2 ocorrências de gradiente/sombra"; "Fraunces aparece 3 vezes". · revisor: Os números estão imprecisos, mas a conclusão vale. battle_replays_screen.dart tem 0 gradientes e 3 BoxShadow. Os estilos display/headline aparecem 4 vezes nos três arquivos (2+1+1). Parte do Fraunces visto nas capturas, como os títulos de AlertDialog, vem do tema e não de uso intencional na tela. Isso reforça a tese do auditor.

**Problemas que o auditor perdeu**

- Idiomas misturados no espectador: a captura mostra 'Turno 2 · Main · Precombat'. O _snapshotPosition (battle_live_spectator_screen.dart:1605-1619) só aplica titleCase na fase crua do motor, enquanto o Coach já tem o mapa em português (battle_coach_screen.dart:2967-2975, 'Principal pré-combate'). É a mesma área com dois vocabulários.
- O app já tem um widget de símbolos de mana, ManaCostRow em app/lib/core/widgets/mana_symbols.dart, e o Battle o usa uma única vez (battle_replays_screen.dart:5534). O painel de decisão do Coach mostra 'Plains — {T}: Add {W}.' em texto cru e o espectador mostra o chip 'Mana 1'. Aproveitar o widget existente seria um ganho rápido de identidade MTG. O auditor viu o rótulo cru, mas não que a solução já existe.
- O fim de partida é inconsistente entre plataformas. No Android o único CTA dourado é 'Analisar replay'. No web o dourado é 'Jogar novamente' e 'Analisar replay' vira botão contornado (07-terminal-replay-rematch.png).
- No terminal por concessão no web, os chips do jogador zeram para 'mão 0 · grimório 0' e aparece a caixa 'Sua mão está vazia'. A barra continua dizendo 'Turno 4 · Combate · Dano de combate'. O momento final parece perda de dados, não encerramento.
- A tela 'Jogar agora' é a porta do contador de vida, não do Battle (home_screen.dart:114-132). Para chegar ao contador tão cuidado, o usuário passa por um bottom sheet de ajustes. O achado pertence à área Home/Contador e ficou escondido dentro do Battle.
- Recibo do pós-jogo (battle_learning_08): logo após salvar, o formulário reaparece zerado com '0 preservar · 0 revisar' e o campo 'Resultado' em foco dourado, embaixo do banner verde. A recompensa é um formulário vazio pedindo novo preenchimento. O auditor criticou o texto do banner, mas não esse reset.
- No espectador mobile, o banner fixo 'Somente acompanhamento' recorta o conteúdo que rola por baixo. Em battle_learning_02 a carta aparece cortada no topo, sem fade nem sombra de separação. O auditor citou a altura do banner, não o recorte.
- No Coach desktop, a pré-visualização de carta no hover (02-private-hand-mulligan.png) fica sobre a divisa entre a mesa e o painel de decisão e cobre parte do vazio central. Ela não tem posição ancorada à carta nem à coluna.

**Afirmações de código conferidas**

- ✅ O seletor de adversário é um AlertDialog (battle_replays_screen.dart:1544) com TextField 'Buscar adversário' em autofocus (:1577), um toggle 'Usar ID técnico' que abre um campo de UUID (:1609-1647) e ListTile com Icons.style_outlined e rádio (:1868-1893). — Confere linha a linha: AlertDialog em :1544, TextField em :1577, TextButton do toggle em :1609, TextField de UUID em :1629 e ListTile em :1868 com leading Icons.style_outlined/public_rounded e trailing radio_button_unchecked.
- ✅ O modelo BattleOpponentDeck (battle_replay_service.dart:84-101) não tem imagem nem identidade de cor, então em produção também não há arte no seletor. — Os campos são id, name, format, source, commanderName, ownerUsername e cardCount. Não há URL de imagem nem cores. A falta de arte é do contrato, não do fixture, e a punição é justa.
- ✅ A concessão usa AlertDialog padrão (battle_coach_screen.dart:318-340) e a ação destrutiva é o FilledButton dourado em :333. — showDialog em :318, AlertDialog em :320, TextButton 'Continuar jogando' em :328 e FilledButton 'Conceder' em :333. A hierarquia invertida está confirmada. Discordo apenas de tratar o diálogo em si como 'formulário'.
- ✅ battle_live_spectator_screen.dart (1.736 linhas) não tem nenhum gradiente nem sombra. Há um Wrap com seis _PublicMetric por jogador em :1028-1061 e o cartão do jogador é chapado, com borda de 1px, em :1007-1016. — wc dá 1736 linhas e o grep por gradient e BoxShadow retorna 0. O Wrap com Vida, Mão, Grimório, Campo, Cemitério e Mana está confirmado, assim como o Container surfaceElevated com Border.all.
- ✅ Os rótulos 'Mao' (:5078) e 'Exilio' (:5107) estão sem acento em battle_replays_screen.dart. — Confere exatamente. O erro é visível na captura 08-replay.png.
- ✅ O pós-jogo tem três TextField empilhados: Resultado (:1272), Nível da mesa em texto livre (:1281) e Notas (:1290). — Confere. O hint do campo 'Nível da mesa' lista as quatro opções fixas ('Casual, melhorada, otimizada ou cEDH'), o que mostra que ele deveria ser uma escolha e não texto livre.
- ❌ O tema já tem lifeCounterWinnerGradient (app_theme.dart:109), sem uso no painel terminal. — O token existe na linha 109, mas não é usado em nenhum lugar do app e é um arco-íris pastel fora da paleta. A recomendação de usá-lo é ruim, embora o diagnóstico do fim de partida esteja certo.
- ✅ As permanentes do campo usam compact: true (battle_coach_screen.dart:1421), a carta virada usa AnimatedRotation 0.25 com CachedCardImage (:1758-1761) e o título do terminal usa titleMedium sans (:2733). — Os três pontos conferem. A arte real em produção via CachedCardImage é confirmada pelas capturas play-vs-ai-web-real, que mostram scans do Scryfall.
- ❌ O Battle Lab tem 2 ocorrências de gradiente/sombra, e o estilo display Fraunces aparece 3 vezes em ~10,9 mil linhas. — A contagem está imprecisa. battle_replays_screen.dart tem 0 gradientes e 3 BoxShadow. Os estilos display/headline aparecem 4 vezes nos três arquivos, que somam 10.898 linhas. A conclusão de que quase não há material nem tipografia display se mantém.
- ✅ A entrada 'Jogar agora' é um showModalBottomSheet em home_screen.dart:132. — A linha confere, mas o sheet é a entrada do contador de vida (guardado por _lifeCounterAllowed em :114 e :123). A tela foi atribuída à área errada.
- ❌ Na versão web do espectador, a mesa inteira são dois blocos de chips. — É artefato do fixture. battle_live_visual_runtime_proof_test.dart:489-502 envia só battlefield_count, sem a lista battlefield. O código em :1063-1070 mostra as zonas com cartas quando as listas chegam, como se vê na captura mobile.
