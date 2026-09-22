# Sequência de conversão das telas e esforço estimado

> **Documentação de apoio, não autoritativa.** Data: 2026-09-21. Complementa [a auditoria visual](visual-audit-2026-09-21/README.md) e a spec do kit. A implementação em `app/lib` só entra depois do gate de evidência de UI (BT-UIEV-001) verde, em worktree próprio, e com o ok do dono para reordenar a fila WIP-1.

## Como o esforço foi medido

Cada padrão antigo que precisa virar objeto vale pontos, conforme o trabalho de redesenho que carrega:

| Padrão | Pontos | Por quê |
|---|---|---|
| `showModalBottomSheet` | 5 | vira tela sobre a superfície viva, com ✕ único |
| `showDialog` / `AlertDialog` | 4 | idem, e normalmente carrega uma decisão |
| `DropdownButton` / `SegmentedButton` / `ExpansionTile` / `Slider` | 3 | escolha escondida que vira peça visível |
| `Switch` / `Checkbox` / `TextField` / `ListTile` / `TabBar` / `PopupMenuButton` | 2 | vira peça-regra, peça ou azulejo |
| `FilledButton` / `ElevatedButton` / `OutlinedButton` / `Chip` | 1 | vira herói, azulejo ou peça acesa |
| `TextButton` | 0,5 | muitos são navegação e sobrevivem como estão |

A contagem é por expressão regular sobre `app/lib`, em [`ui-kit/primitive-counts.json`](ui-kit/primitive-counts.json). É um **teto aproximado**: conta ocorrências no código, não telas.

**O ponto cego desta métrica:** ela só enxerga widget do Material. Uma tela que fez as próprias linhas de formulário à mão — caso do onboarding, com `_GoalRail`, `_GoalRow` e `_BuildModeTile` — pontua baixo e mesmo assim dá trabalho. Por isso a coluna **linhas** entra junto, e a classe de tamanho é a pior das duas: **P** < 15 pontos e < 1.500 linhas · **M** até 39 pontos ou 3.500 linhas · **G** até 89 pontos ou 6.000 linhas · **XG** acima disso.

**Total fora do contador: 949 pontos** em 17 áreas. Para comparar, os sheets nativos do próprio contador somam **196 pontos** — eles também contradizem a régua hoje e estão sendo convertidos pela sessão que cuida do protótipo.

## A sequência

A ordem é por impacto sobre a primeira impressão dividido por esforço, não por nota. Uma tela feia que ninguém vê espera; uma tela mediana que todo mundo vê, não.

### Onda 1 — a porta de entrada

Todo usuário novo passa aqui. São as telas que decidem a primeira impressão do produto, e as três são baratas de converter.

| # | Tela | Arquivos | Pontos | Linhas | Classe | Nota hoje | Por que agora |
|---|---|---|---|---|---|---|---|
| 1.1 | **Onboarding "Seu primeiro passo"** | `onboarding_core_flow_screen.dart` | 6 | 1526 | M | 1.9 | Primeira tela do usuário novo. Hoje é um wizard numerado em 3 caixas. Poucos widgets Material, mas as linhas e os azulejos são feitos à mão: o esforço está nas 1.526 linhas, não nos 6 pontos. |
| 1.2 | **Gerador de Decks com IA** | `deck_generate_screen.dart`<br>`ai_usage_gate.dart`<br>`ai_usage_meter.dart` | 33 | 2486 | M | 1.4 | É a promessa central do produto e a tela com a pior nota da auditoria. |
| 1.3 | **Home** | `home_screen.dart` | 13 | 2227 | M | 3.0 | Tela mais vista do app. Barata: o herói já existe, falta o resto da tela existir. |

### Onda 2 — o núcleo (decks)

A área com mais código e mais peso de conversão do app. Vem logo depois da porta de entrada porque é onde o usuário passa o tempo.

| # | Tela | Arquivos | Pontos | Linhas | Classe | Nota hoje | Por que agora |
|---|---|---|---|---|---|---|---|
| 2.1 | **Detalhe do deck + seus diálogos** | `deck_details_screen.dart`<br>`deck_details_dialogs.dart`<br>`deck_details_overview_tab.dart` | 107 | 5327 | XG | 3.0 | O arquivo de diálogos sozinho é o 3º maior peso do app. Já tem task registrada (BT-UX-DECK-002). |
| 2.2 | **Lista de decks, criar e importar** | `deck_list_screen.dart`<br>`deck_import_screen.dart`<br>`deck_import_list_dialog.dart`<br>`deck_card_edit_dialog.dart` | 90 | 4980 | XG | 1.6 | Criar deck e importar lista são dois formulários em diálogo. |
| 2.3 | **Otimização (prévia, trocas pareadas, resultado)** | `deck_optimize_dialogs.dart`<br>`deck_optimize_sheet_widgets.dart`<br>`deck_optimize_sections.dart` | 66 | 4661 | G | 1.4 | Seis overlays empilhados. A troca pareada SAI→ENTRA é o caso perfeito para peça com miniatura (BT-UX-SWAP-001). |
| 2.4 | **Aba Análise do deck** | `deck_analysis_tab.dart` | 20 | 2594 | M | sem captura | ~4.900 linhas de UI que nunca foram fotografadas nem julgadas. Precisa de captura antes de estimar. |

### Onda 3 — coleção

O fichário é onde o usuário coloca o que é dele. Hoje é a área mais parecida com planilha.

| # | Tela | Arquivos | Pontos | Linhas | Classe | Nota hoje | Por que agora |
|---|---|---|---|---|---|---|---|
| 3.1 | **Importar coleção** | `binder_import_screen.dart` | 42 | 1485 | G | 2.1 | Dropdowns de condição e idioma por carta, em fila. |
| 3.2 | **Editor de carta do fichário** | `binder_item_editor.dart` | 28 | 1336 | M | 1.4 | Segmentado + stepper + chips + 3 interruptores + 2 campos numa tela só. |
| 3.3 | **Fichário (abas Tenho/Quero, resumo, filtros)** | `binder_screen.dart` | 20 | 2097 | M | 2.4 | Só foi fotografado vazio e com 1 carta; a densidade real nunca foi julgada. |

### Onda 4 — social e trocas

Onde o produto encontra outras pessoas. Nota baixa e quase nenhum gradiente ou sombra em todo o grupo.

| # | Tela | Arquivos | Pontos | Linhas | Classe | Nota hoje | Por que agora |
|---|---|---|---|---|---|---|---|
| 4.1 | **Detalhe e criação de trade** | `trade_detail_screen.dart`<br>`create_trade_screen.dart` | 52 | 3657 | G | 1.8 | Caixas cinzas empilhadas com parágrafos; a carta aparece em 36x50 px. |
| 4.2 | **Perfil público e deck da comunidade** | `user_profile_screen.dart`<br>`community_deck_detail_screen.dart` | 57 | 2921 | G | 3.0 | Duas telas de vitrine que hoje são lista. |
| 4.3 | **Chat e denúncia** | `chat_screen.dart`<br>`social_report_dialog.dart` | 32 | 707 | M | sem captura | O chat com mensagens nunca foi fotografado — só o estado indisponível. |

### Onda 5 — battle

Tem o arquivo mais pesado do app inteiro. Fica depois do núcleo porque é a área com menos tráfego hoje.

| # | Tela | Arquivos | Pontos | Linhas | Classe | Nota hoje | Por que agora |
|---|---|---|---|---|---|---|---|
| 5.1 | **Battle Lab / replays** | `battle_replays_screen.dart` | 118 | 6178 | XG | 1.5 | 118 pontos: o maior peso de conversão de um arquivo só em todo o app. |
| 5.2 | **Battle Coach e seletor de adversário** | `battle_coach_screen.dart` | 25 | 2984 | M | 1.6 | A mesa ativa já é a melhor tela da área; o entorno é que é formulário. |
| 5.3 | **Pós-jogo** | `post_game_notes_screen.dart` | 16 | 1969 | M | 2.1 | Momento de maior emoção do usuário, tratado como formulário de notas. |

### Onda 6 — conta, planos e entrada

Formulário é legítimo em login, senha e texto legal. O que muda é a moldura, não o campo.

| # | Tela | Arquivos | Pontos | Linhas | Classe | Nota hoje | Por que agora |
|---|---|---|---|---|---|---|---|
| 6.1 | **Perfil e segurança** | `profile_screen.dart` | 92 | 2348 | XG | 1.8 | 92 pontos num arquivo só: 6 diálogos, 10 campos, 13 TextButton. |
| 6.2 | **Planos, checkout e upgrade** | `checkout_screen.dart` | 1 | 74 | P | 1.6 | Pior nota da área: parede de texto jurídico e chips com jargão de engenharia. |
| 6.3 | **Cadastro e consentimento** | `register_screen.dart` | 12 | 668 | P | 2.1 | Manter o campo, trocar a moldura: o consentimento pode ser peça-regra que acende. |

Somando só as telas nomeadas: **830 pontos**. O resto dos 949 está espalhado em telas menores (notificações, cartas, catálogo, scanner) que pegam carona no kit sem redesenho dedicado.

## Onda 0 — a ponte (pré-requisito de tudo)

Não é tela e não entra na contagem, mas nada acima começa sem isto:

1. Extrair as cinco primitivas para `app/lib/core/widgets`, conforme a spec do kit.
2. Revogar em `app/lib/core/theme/app_theme.dart` a regra 4 da linha 18 ("Gradients only for hero sections and primary buttons") e o `cardGradient` "intentionally flat" das linhas 183–188. Enquanto elas valerem, o app é chapado por contrato.
3. Adicionar o guarda de regressão no molde de `app/test/core/theme/app_theme_token_usage_test.dart`, que falha quando uma feature usa padrão proibido fora da lista de exceções. Sem isso a régua volta a depender de revisão manual.
4. Limpar os 52 tokens `lifeCounter*` sem uso em `app/lib`.

## Capturas que faltam para a próxima auditoria

A auditoria de hoje julgou 85 telas, mas várias notas caíram sobre o estado vazio, que é bonito, e não sobre a tela com dados. Sem estas capturas, a próxima rodada volta a medir o `AppStatePanel`:

| Falta | Por quê |
|---|---|
| **Scanner de carta** (`/decks/:id/search/scan`): prévia da carta lida, não encontrada, permissão de câmera negada | Zero capturas e zero goldens em qualquer perfil. É a única rota do app sem nenhuma imagem. |
| **Aba Cartas** do detalhe do deck (100 cartas agrupadas, swipe editar/excluir) | Nunca fotografada. |
| **Aba Análise** do detalhe do deck (métricas, curva, pizza de cores, plano Commander) | ~4.900 linhas de UI nunca julgadas. É a maior superfície não vista do produto. |
| **Telas sociais com dados**: chat com mensagens, caixa de mensagens, caixa de trades, notificações, feed Seguindo, Cotações populada | Só existem vazias ou em erro. |
| **Lista de decks com muitos decks** e **fichário populado** (abas Tenho/Quero, resumo expandido, filtros ativos) | A densidade real nunca foi julgada: as capturas têm 1 item. |
| **Diálogos sem captura**: editar carta do deck, editor de descrição, seletor de edição, denúncia, gate de IA | Boa parte dos 51 diálogos e 24 sheets do inventário oficial do repo. |
| **Estados de carregamento / skeleton** de praticamente todas as telas | A auditoria só viu telas prontas ou em erro. |
| **Tema claro** | Todas as 439 capturas são do tema escuro. Ninguém sabe como o app está no claro. |
| **iOS** | Nenhum perfil de captura é iOS: só web 390/1440/1920 e Android. |
