# ManaLoom Visual Density Audit — iPhone 15 Simulator — 2026-05-07

## Resultado final

**PASS WITH RISKS** para a auditoria visual/densidade no **iPhone 15
Simulator** (`F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4) contra o
backend publico `https://evolution-cartinhas.8ktevp.easypanel.host`.

Scanner, camera, OCR e MLKit scanner ficaram **100% ignorados**. Nenhuma
alteracao foi feita em backend runtime, banco, contratos, IA, scanner, secrets
ou configuracao de deploy.

## Fontes consultadas

| Fonte | Uso na auditoria |
| --- | --- |
| `app/lib/core/theme/app_theme.dart` | Baseline Obsidian + Brass + Frost Blue, escala Manrope/Fraunces, raio e tokens. |
| `docs/qa/manaloom_android_design_audit_sm_a135m_2026-05-07.md` | Comparacao com passadas Android SM A135M e riscos ja aceitos. |
| `docs/qa/manaloom_ux_psychology_design_audit_2026-04-30.md` | Historico de findings UX, CTA, confiança, erros amigaveis e semantica de cores. |
| `app/doc/APP_AUDIT_2026-04-29.md` | Linha do tempo de auditorias/release non-scanner. |
| `app/doc/runtime_flow_handoffs/` | Handoffs recentes de iPhone/Android non-scanner, Binder, Trades, Deck runtime e Sets. |

## Device, backend e autenticacao

| Item | Resultado |
| --- | --- |
| Branch | `master`, sincronizada com `origin/master` |
| Device | iPhone 15 Simulator, id `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, iOS 17.4, `Booted` |
| Backend | `https://evolution-cartinhas.8ktevp.easypanel.host` |
| Health | `healthy`, production, `version=1.0.0`, `git_sha=cbfea7356c5e84c51f7adce7ec4b7f7eae2a4a60` |
| Auth QA | contas QA descartaveis criadas/autenticadas pelos harnesses; senha/token/JWT/header/payload sensivel nao documentados |
| Escopo excluido | Scanner/camera/OCR/MLKit scanner |

## Comandos executados e resultados

| Comando | Resultado |
| --- | --- |
| `git status --short --branch`, `git fetch origin master`, `git checkout master`, `git pull --ff-only origin master` | PASS; branch `master` atualizada. |
| `curl -sS --max-time 10 https://evolution-cartinhas.8ktevp.easypanel.host/health` | PASS; backend `healthy`, `git_sha=cbfea7356c5e84c51f7adce7ec4b7f7eae2a4a60`. |
| `cd app && flutter devices --no-version-check` | PASS; iPhone 15 Simulator detectado. |
| `xcrun simctl list devices available` + `xcrun simctl boot "iPhone 15"` | PASS; iPhone 15 `Booted`. |
| `flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart -d "iPhone 15" ...public backend...` | PASS, `00:44 +1`; capturas Auth, Home, Decks, Deck Detail, Generate, Community, Collection, Profile. |
| `flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" ...public backend...` | PASS, `00:27 +1`; capturas Search/Cards, Card Detail, Sets/Colecoes e Set Detail. |
| `flutter test integration_test/binder_dashboard_runtime_test.dart -d "iPhone 15" ...public backend...` | PASS, `00:29 +1`; capturas Binder dashboard, busca e sheets add/edit. |
| `flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" ...public backend...` | PASS, `01:09 +2`; capturas Binder, Marketplace, Trades, Trade Detail, chat, Notifications e Messages. |
| `flutter test integration_test/deck_generate_async_runtime_test.dart -d "iPhone 15" ...public backend...` | PASS, `00:54 +1`; capturas Generate async, preview, save, Deck Detail, Optimize sheet e blocker amigavel. |
| `flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" ...RUNTIME_OPTIMIZE_INTENSITY_LABEL=Focado...` | PASS WITH RISKS; capturou Optimize, Preview, selecao parcial e `10_complete_validated`, mas falhou depois por assertion de sinal textual de conclusao. Nao houve indicio de overflow/crash visual. |
| `flutter test integration_test/life_counter_native_player_state_smoke_test.dart -d "iPhone 15"` | PASS, `00:25 +2`; capturas Lotus table e Player State overlays. |
| `cd app && flutter analyze lib test --no-version-check` | PASS, sem issues. |
| `cd app && flutter test test --no-version-check` | PASS, suite unit/widget completa (`551` testes, rodada pelo auditor especializado antes da materializacao final dos PNGs). |

Observacao: os logs brutos dos harnesses foram usados apenas para extrair os
PNGs e depois removidos do diretorio de prova para evitar registrar payloads ou
chunks extensos. O relatorio mantem somente resultados sanitizados.

## Provas persistidas

Diretorio de screenshots: `app/doc/runtime_flow_proofs_2026-05-07_iphone15_visual_density/`

Foram materializados **57 PNGs**. Principais arquivos:

| Tela/fluxo | Evidencia |
| --- | --- |
| Auth/Login | `app_full.raw_01_login.png` |
| Register | `app_full.raw_02_register_filled.png` |
| Home | `app_full.raw_03_home.png` |
| Decks | `app_full.raw_04_decks.png`, `deck_runtime.raw_03_decks.png` |
| Criacao de deck | `app_full.raw_04a_create_deck_dialog.png`, `deck_runtime.raw_04_deck_created.png` |
| Deck Detail | `app_full.raw_04b_deck_details.png`, `generate_async.raw_08_deck_details.png` |
| Generate | `app_full.raw_05_generate.png`, `generate_async.raw_04_generate_screen.png`, `generate_async.raw_06_generate_preview.png` |
| Optimize/Validate | `deck_runtime.raw_08_optimize_sheet.png`, `deck_runtime.raw_09_preview.png`, `deck_runtime.raw_10_complete_validated.png` |
| Search/Cards | `sets_search.raw_sets_search_01_cards_results.png` |
| Card Detail | `sets_search.raw_sets_search_02_card_detail.png` |
| Sets/Colecoes | `sets_search.raw_sets_search_03_collections_results.png` |
| Set Detail | `sets_search.raw_sets_search_04_set_detail.png` |
| Binder dashboard | `binder_dashboard.raw_binder_01_dashboard.png` |
| Binder add/edit | `binder_dashboard.raw_binder_03_add_item_sheet.png`, `binder_dashboard.raw_binder_04_edit_item_sheet.png` |
| Marketplace | `marketplace_trades.raw_market_trade_02_marketplace_result.png` |
| Trades list/detail | `marketplace_trades.raw_market_trade_05_trade_list.png`, `marketplace_trades.raw_market_trade_06_trade_detail_pending.png`, `marketplace_trades.raw_market_trade_10_trade_detail_completed.png` |
| Trade chat | `marketplace_trades.raw_market_trade_08_trade_chat.png` |
| Messages | `marketplace_trades.raw_messages_01_inbox.png`, `marketplace_trades.raw_messages_02_conversation.png` |
| Notifications | `marketplace_trades.raw_market_trade_11_notifications.png` |
| Profile | `app_full.raw_09_profile.png` |
| Community | `app_full.raw_07_community.png` |
| Life Counter/Lotus | `life_counter.raw_life_counter_01_lotus_table.png`, `life_counter.raw_life_counter_02_player_state.png`, `life_counter.raw_life_counter_03_player_state_killed_overlay.png` |

## Matriz tela-a-tela

| Tela/modulo | Status | Auditoria visual/densidade |
| --- | --- | --- |
| Auth / Login | OK | Hierarquia clara, CTA Brass legivel, densidade confortavel para 390x844; sem erro tecnico cru exposto. |
| Register | OK | Campos e CTA mantem ritmo vertical adequado; labels legiveis em Manrope, contraste suficiente em Obsidian. |
| Home | OK | Identidade Obsidian/Brass/Frost preservada; secoes com margem externa consistente e cards sem overload critico no iPhone 15. |
| Search/Cards | OK | Lista prioriza arte/nome da carta; spacing entre resultados e area de busca sem clipping observado. |
| Card Detail | OK | Conteudo denso por natureza de carta, mas imagem e blocos informativos preservam hierarquia; sem overflow fatal observado. |
| Sets/Colecoes | OK | Busca e lista usam semantica nao-IA; tabs/labels permanecem legiveis no iPhone 15. |
| Set Detail | OK | Grade/lista de cartas segue ritmo de Collection; empty/loading path seguro. |
| Decks | OK | Cards de deck com boa separacao, CTA principal claro e dialog de criacao sem excesso visual. |
| Deck Detail | OK | Comandante, contagem, preco/curva e acoes principais continuam com hierarquia funcional. |
| Generate | Needs polish | Harness amplo ainda capturou `generate_preview_not_proven`, mas o harness dedicado provou preview/salvamento. Estado async e bom, porem a confianca visual depende da prova dedicada. |
| Optimize | Needs polish | Sheet e preview foram capturados; fluxo `Focado` chegou a validacao visual, mas o harness falhou apos a captura por sinal textual. Nao aplicar patch visual sem bug reproduzido. |
| Validate | Needs polish | Captura `10_complete_validated` existe e backend respondeu 200; risco fica no harness/assertion final, nao em layout confirmado. |
| Binder/Fichario | OK | Dashboard, busca e sheets add/edit mantem densidade alta mas escaneavel; chips e filtros legiveis. |
| Binder dashboard | OK | Cards de estatisticas e distribuicoes usam superfícies escuras e espacos consistentes; sem overcrowding critico. |
| Marketplace | OK | Card de oferta exibe dono, preco, condicao e contexto com boa hierarquia de confianca. |
| Trades list/detail | OK | Lista, revisao e timeline/detail deixam status e acoes claras; CTAs criticos ja tinham confirmacao em passadas anteriores. |
| Trade chat | OK | Chat contextual de trade diferencia conversa transacional de DM geral. |
| Messages/Conversations | OK | Inbox e conversa com densidade baixa, bolhas legiveis e empty state seguro. |
| Notifications | OK | Lista de notificacoes legivel; badges/estado de leitura sem poluicao visual relevante. |
| Profile | OK | Avatar/nome/tabs mantem hierarchy clara e sem competicao de cores. |
| Community | OK | Feed/tabs seguem padrao app; cards publicos nao exibem cor excessiva. |
| Life Counter/Lotus | OK | Numeros e overlays cabem no iPhone 15; Player State nao apresentou overflow horizontal. |
| Scanner/camera/OCR/MLKit | Ignored | Fora de escopo por instrucao. |

## Findings classificados

| ID | Prioridade | Finding | Status |
| --- | --- | --- | --- |
| UX-I15-DENS-001 | P1 | `deck_runtime_m2006_test.dart` capturou o estado visual completo/validado, mas falhou depois porque o texto de conclusao esperado nao estava mais presente no frame final. | Needs follow-up de harness ou criterio de assert; sem patch visual seguro aplicado. |
| UX-I15-DENS-002 | P2 | Generate tem duas evidencias: o harness amplo marca preview nao provado, enquanto o harness async dedicado prova preview/save/detail. | Needs polish de evidencia/tempo de job, nao bug visual confirmado. |
| UX-I15-DENS-003 | P2 | Warnings extensos de plugins iOS Simulator arm64 aparecem mesmo em execucoes non-scanner por dependencias camera/Firebase/MLKit. | Tooling noise; Scanner continuou ignorado. |
| UX-I15-DENS-004 | P2 | Search global ainda divide cards e colecoes por abas; uma busca universal unica seria decisao de produto. | Needs product decision. |
| UX-I15-DENS-005 | P3 | Card Detail e Binder add/edit sao naturalmente densos e devem seguir sendo monitorados em telas menores; no iPhone 15 nao houve overflow fatal. | Monitorar em futuras passadas. |

## Avaliacao de design system/densidade

| Criterio | Avaliacao |
| --- | --- |
| Fonte/familia | UI segue Manrope via `AppTheme`; titulos/display usam baseline Fraunces quando suportado. |
| Tamanho/peso/line-height | Escala `fontXs` a `fontDisplay` mantida; captions/chips ainda densos, mas legiveis nas provas. |
| Contraste aproximado | Obsidian + textPrimary/textSecondary apresentam contraste adequado; CTA Brass com foreground escuro permanece correto onde observado. |
| Cards/padding/margens | Cards principais mantem raio `radiusMd/Lg`, padding confortavel e ritmo de lista consistente. |
| Icones | Nenhum icone indevido de IA foi identificado nas capturas iPhone 15; Colecoes segue sem semantica AI. |
| CTAs | Acoes primarias usam Brass; acoes AI usam Frost Blue em telas tocadas anteriormente; hierarquia clara. |
| Chips/badges/filtros | Densos em Binder/Marketplace, mas escaneaveis e sem truncamento critico no iPhone 15. |
| Loading/empty/error | Estados async de Generate/Optimize aparecem amigaveis; sem erro tecnico cru visivel nas capturas. |
| Overflow/clipping | Nenhum `RenderFlex overflowed` encontrado nos logs da rodada iPhone 15; falha remanescente e de assert textual. |
| Poluicao visual | App preserva baixa saturacao global; WUBRG continua restrito a mana/identidade quando observado. |

## Patches aplicados

Nenhum patch visual de runtime foi aplicado nesta rodada. A auditoria encontrou
riscos de harness/evidencia e uma decisao de produto, mas nao identificou P0/P1
visual deterministico que justificasse mudanca de padding, cor, contrato visual
ou layout sem risco.

Mudancas realizadas nesta tarefa:

- criacao deste relatorio;
- materializacao de 57 screenshots PNG no diretorio de prova iPhone 15;
- atualizacao das notas historicas em `app/doc/APP_AUDIT_2026-04-29.md` e
  `server/manual-de-instrucao.md`.

## Itens nao verificados / riscos

- O harness `deck_runtime_m2006_test.dart` precisa de follow-up para alinhar o
  assert final ao estado visual capturado ou esperar o texto de validacao
  reaparecer apos o refresh do deck.
- A prova ampla de Generate ainda pode terminar antes do preview, embora a prova
  dedicada de Generate async tenha passado.
- Nao foi feita auditoria manual pixel-level com medicao numerica de contraste
  por cor de cada screenshot; a avaliacao foi baseada nos tokens, runtime real e
  ausencia de overflow/crash visual.
- Scanner/camera/OCR/MLKit scanner nao foram abertos nem avaliados.

## Veredito

**PASS WITH RISKS**.

O app autenticado real foi exercitado no iPhone 15 Simulator contra backend
publico, com screenshots persistidos para todas as superficies non-scanner em
escopo. A identidade Obsidian/Brass/Frost Blue, a densidade de cards e a
hierarquia de CTAs permanecem consistentes. Os riscos remanescentes sao de
harness/evidencia em Deck runtime/Generate amplo e uma decisao de produto para
busca global; nao ha P0 visual confirmado.
