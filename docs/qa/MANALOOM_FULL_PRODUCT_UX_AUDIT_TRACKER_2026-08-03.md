# Tracker — auditoria integral de produto e UX do ManaLoom

**Atividade-mãe:** [MANALOOM_FULL_PRODUCT_UX_AUDIT_ACTIVITY_2026-08-03.md](MANALOOM_FULL_PRODUCT_UX_AUDIT_ACTIVITY_2026-08-03.md)

**Estado global:** `DIAGNOSTIC_COMPLETE · UX_PACKS_01_08_COMPLETE_LOCAL · POLISH_P2_COMPLETE_LOCAL · CURRENT_WEB_25_402_VISUAL_COMPLETE · ANDROID_PHYSICAL_1_54_STALE · GLOBAL_REANCHOR_INCOMPLETE · RELEASE_HUMAN_GATES_PENDING · COUNSEL_SIGNOFF_LAST`

**Execução:** `ROUTES_AND_JOURNEYS_COMPLETE`; `UX_PACKS_01_08_COMPLETE_LOCAL`; `POLISH_P2_COMPLETE_LOCAL`; `25_MANIFESTS_402_SCREENSHOTS_CURRENT_DIGEST`; `402_CURRENT_WEB_SCREENSHOTS_VISUAL_REVIEWED`; `P0_WEB_3_160_CURRENT`; `P0_PHYSICAL_1_54_STALE`; `GLOBAL_AGGREGATE_REANCHOR_PENDING`

**Regra:** nenhuma linha `NOT_STARTED` representa defeito; nenhuma linha histórica representa aprovação atual.

## 1. Vocabulário de status

| Status | Uso |
|---|---|
| `NOT_STARTED` | Não inspecionado na rodada fresca |
| `INVENTORIED` | Existência reconciliada com código/manifesto |
| `CAPTURED` | Evidência fresca produzida, ainda não necessariamente aberta |
| `VISUAL_REVIEWED` | Todas as capturas aplicáveis foram abertas e julgadas |
| `FUNCTION_REVIEWED` | Job, ação, sucesso e recuperação foram exercitados |
| `GAP_CONFIRMED` | Problema reproduzido e documentado |
| `RESOLVED` | Causa e consequência verificadas como fechadas no digest corrente |
| `NO_GAP_FOUND` | Nenhuma lacuna encontrada no escopo exercitado; não equivale a garantia universal |
| `DEFERRED_BY_SCOPE` | Superfície deliberadamente indisponível, com comunicação a auditar |
| `NOT_APPLICABLE` | Critério não pertence à superfície, com justificativa |
| `BLOCKED` | Evidência não pode ser obtida; motivo e próxima ação obrigatórios |

## 2. Cobertura a reconciliar

| Tipo | Esperado | Auditado | Estado |
|---|---:|---:|---|
| `GoRoute` | 45 | 45 | `FUNCTION_OR_VISUAL_REVIEWED`; 3 deferred e 3 redirects explicitados |
| `ShellRoute` | 1 | 1 | `VISUAL_REVIEWED` |
| `MaterialPageRoute` | 7 | 7 | `INVENTORIED`; equivalentes críticos exercitados, prova individual pendente |
| Diálogos | 51 | 51 | `INVENTORIED`; somente amostra corrente aberta, expansão obrigatória |
| Bottom sheets | 24 | 24 | `INVENTORIED`; entrada de partida, seletor de printing, Optimize e Binder exercitados, demais pendentes |
| Menus | 9 | 9 | `INVENTORIED`; prova action-open-final pendente |
| Abas | 10 | 10 | `FUNCTION_OR_VISUAL_REVIEWED` |
| Navegações | 2 | 2 | `VISUAL_REVIEWED` |
| Transientes | 114 | 114 | `INVENTORIED`; padrões críticos amostrados, rastreabilidade por ocorrência pendente |
| Arquivos-fonte | 60 | 60 | `INVENTORIED` |
| **Ocorrências totais** | **263** | **263** | **`INVENTORIED`; prova integral por ocorrência ainda não concluída** |

## 3. Ledger das 45 rotas

Cada rota deve gerar uma worksheet ou apontar para uma worksheet compartilhada que prove equivalência real entre estados.

| # | Onda | Domínio | Rota canônica | Superfície | Escopo atual | Auditoria |
|---:|---:|---|---|---|---|---|
| 1 | 0 | shell | `/` | `SplashScreen` | active | `VISUAL_REVIEWED` |
| 2 | 0 | auth | `/login` | `LoginScreen` | active | `FUNCTION_REVIEWED` |
| 3 | 0 | auth | `/register` | `RegisterScreen` | active | `VISUAL_REVIEWED` |
| 4 | 0 | auth | `/forgot-password` | `ForgotPasswordScreen` | active | `VISUAL_REVIEWED` |
| 5 | 0 | auth | `/reset-password` | `ResetPasswordScreen` | active | `VISUAL_REVIEWED` |
| 6 | 6 | commercial | `/legal` | `CommercialLegalScreen` | active | `FUNCTION_REVIEWED` |
| 7 | 0 | auth | `/verify-email` | `VerifyEmailScreen` | active | `VISUAL_REVIEWED` |
| 8 | 4 | home | `/life-counter` | `LotusLifeCounterScreen` | active | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 9 | 1 | home | `/home` | `HomeScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 10 | 1 | home | `/onboarding/core-flow` | `OnboardingCoreFlowScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED · GAP_RESOLVED_LOCAL` |
| 11 | 3 | decks | `/decks` | `DeckListScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED · FIRST_USE_RESOLVED_LOCAL` |
| 12 | 3 | decks | `/decks/generate` | `DeckGenerateScreen` | active | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 13 | 3 | decks | `/decks/import` | `DeckImportScreen` | active | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 14 | 3 | decks | `/decks/:id` | `DeckDetailsScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED · GAP_CONFIRMED` |
| 15 | 2 | cards | `/decks/:id/search` | `CardSearchScreen` | active | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 16 | 2 | scanner | `/decks/:id/scan` | `CardScannerScreen` | deferred | `DEFERRED_BY_SCOPE` |
| 17 | 4 | retention | `/decks/:id/post-game` | `PostGameNotesScreen` | active | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 18 | 4 | battle | `/decks/:id/battle-replays` | `BattleReplaysScreen` | active | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 19 | 4 | battle | `/decks/:id/battle-coach/:sessionId` | `BattleCoachScreen` | deferred | `DEFERRED_BY_SCOPE` |
| 20 | 4 | battle | `/decks/:id/battle-coach` | `BattleCoachScreen` | deferred | `DEFERRED_BY_SCOPE` |
| 21 | 4 | battle | `/decks/:id/battle-live/:jobId` | `BattleLiveSpectatorScreen` | active | `VISUAL_REVIEWED · GAP_CONFIRMED` |
| 22 | 6 | commercial | `/plans` | `PlanScreen` | active/beta policy | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 23 | 2 | cards | `/cards/:cardId` | `CardDetailRouteScreen` | active | `FUNCTION_REVIEWED` |
| 24 | 6 | commercial | `/upgrade` | `UpgradeScreen` | active/beta policy | `FUNCTION_REVIEWED` |
| 25 | 6 | commercial | `/checkout` | `CheckoutScreen` | active/beta policy | `FUNCTION_REVIEWED` |
| 26 | 2 | collection | `/collection` | `CollectionScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED · GAP_CONFIRMED` |
| 27 | 2 | collection | `/collection/latest-set` | `LatestSetCollectionScreen` | active | `VISUAL_REVIEWED · GAP_CONFIRMED` |
| 28 | 2 | collection | `/collection/sets` | `SetsCatalogScreen` | active | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 29 | 2 | collection | `/collection/sets/:code` | `SetCardsScreen` | active | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 30 | 5 | market | `/market` | redirect → `/community?tab=3` | legacy quotes redirect | `FUNCTION_REVIEWED · RESOLVED` |
| 31 | 5 | community | `/community` | `CommunityScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 32 | 5 | social | `/community/search-users` | `UserSearchScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 33 | 5 | social | `/community/user/:userId` | `UserProfileScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED · GAP_RESOLVED_LOCAL` |
| 34 | 5 | community | `/community/decks/:deckId` | `CommunityDeckDetailScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 35 | 6 | profile | `/profile` | `ProfileScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED · GAP_RESOLVED_LOCAL` |
| 36 | 5 | messages | `/messages` | `MessageInboxScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 37 | 5 | messages | `/messages/:conversationId` | `ChatScreen` | active | `VISUAL_REVIEWED · GAP_CONFIRMED` |
| 38 | 5 | notifications | `/notifications` | `NotificationScreen` | active | `FUNCTION_REVIEWED · GAP_CONFIRMED` |
| 39 | 5 | trades | `/trades` | `TradeInboxScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 40 | 5 | trades | `/trades/create/:receiverId` | `CreateTradeScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 41 | 5 | trades | `/trades/:tradeId` | `TradeDetailScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 42 | 2 | binder | `/collection/import` | `BinderImportScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 43 | 5 | trades | `/collection/matches` | `TradeMatchesScreen` | active | `FUNCTION_AND_FOCAL_VISUAL_REVIEWED` |
| 44 | 5 | market | `/marketplace` | redirect → `/collection?tab=1` | semantic redirect | `FUNCTION_REVIEWED · RESOLVED` |
| 45 | 5 | market | `/quotes` | redirect → `/community?tab=3` | semantic redirect | `FUNCTION_REVIEWED · RESOLVED` |

## 4. Hotspots de superfícies não-route

Estes números vêm de `ui_surface_inventory.json`. No kickoff, cada ocorrência deve ganhar ID, trigger, owner, estado, decisão modal e worksheet/referência.

| Domínio | Arquivos | Page routes | Dialogs | Sheets | Menus | Tabs | Nav | Transientes | Risco inicial a investigar |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| decks | 12 | 0 | 22 | 4 | 5 | 1 | 0 | 47 | Fluxos centrais fragmentados em overlays e feedback efêmero |
| home | 16 | 0 | 3 | 15 | 0 | 0 | 0 | 7 | Ferramentas do Life Counter e progressive disclosure |
| battle | 2 | 0 | 7 | 0 | 1 | 0 | 0 | 5 | Decisões, falhas e privacidade da sessão |
| profile | 1 | 0 | 6 | 0 | 0 | 0 | 0 | 8 | Ações sensíveis e confirmações necessárias |
| trades | 3 | 0 | 3 | 1 | 0 | 2 | 0 | 6 | Estado bilateral, confiança e informação persistente |
| social | 3 | 1 | 2 | 1 | 1 | 2 | 0 | 5 | Contexto de pessoa/carta e ações escondidas |
| cards | 3 | 1 | 2 | 1 | 0 | 1 | 0 | 6 | Busca, impressão e seleção contextual |
| binder | 3 | 4 | 3 | 1 | 0 | 1 | 0 | 1 | Edição, propriedade, lote e imagem correta |
| community | 2 | 0 | 1 | 0 | 1 | 2 | 0 | 7 | Densidade, filtros, cards e CTA concorrentes |
| messages | 1 | 0 | 1 | 0 | 1 | 0 | 0 | 3 | Rascunho, envio e contexto do usuário |
| commercial | 2 | 0 | 1 | 0 | 0 | 0 | 0 | 3 | Beta gratuita, limites e CTA indisponível |
| collection | 3 | 1 | 0 | 0 | 0 | 1 | 0 | 2 | Abas, deep link e distinção vazio/erro |
| shell | 2 | 0 | 0 | 0 | 0 | 0 | 2 | 0 | Orientação e consistência responsiva |
| auth | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 3 | Falhas comunicadas somente por transiente |
| scanner | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 4 | Estado deferido e fallback para busca manual |
| retention | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | Save/offline sem perder draft |
| notifications | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | Ação e erro de read state |

## 5. Ledger de ocorrências não-route

O inventário foi reconciliado nesta rodada. A linha agregada abaixo registra cobertura
estrutural, não substitui as 263 provas individuais exigidas para encerrar o DoD visual.

| ID | Tipo | Domínio | Arquivo:linha | Trigger | Job | Taxonomia | Decisão | Evidência | Status |
|---|---|---|---|---|---|---|---|---|---|
| `ALL-263` | page/dialog/sheet/menu/tab/nav/transient | 18 domínios | `ui_surface_inventory.json` | inventário estático | reconciliar superfície e risco | por tipo | manter/prometer/reprojetar por pacote | código + amostra runtime/visual | `INVENTORIED · INDIVIDUAL_PROOF_PENDING` |

## 5.1 Fila inicial de investigação

São sinais estáticos, não verdictos visuais. A execução deve confirmar, refutar ou reclassificar cada linha.

| ID | Superfície | Sinal | Evidência atual | Próxima prova | Status |
|---|---|---|---|---|---|
| `SEED-01` | inventário/documentação | inventário corrente = 263 superfícies: 45 GoRoute, 1 ShellRoute, 7 MaterialPageRoute, 51 dialogs, 24 sheets, 9 menus, 10 tabs, 2 navegações e 114 transientes | `CODE_SEEN · AUTOMATED_PASS` | preservar o gerador e reconciliar a cada mudança app-facing | `RECONCILED_CURRENT` |
| `SEED-02` | matriz visual | a matriz P0 mantém 54 checkpoints máximos por perfil; o Pack 08 acrescentou 22 checkpoints críticos em três perfis Web | 402/402 PNGs Web correntes foram cobertos pela revisão final; as 54 capturas físicas abertas são históricas e continuam stale | recapturar o SM-A135M; não transportar crédito antigo | `CURRENT_WEB_RECONCILED · PHYSICAL_REANCHOR_PENDING` |
| `SEED-03` | estados transversais | session-expired, permission-denied, loading/error/retry/recovered e falhas persistentes agora têm prova focal explícita | `AUTOMATED_PASS · 3 WEB RELEASE PROFILES_OPENED` | preservar por domínio e executar acessibilidade/hardware de release | `RESOLVED_FOR_UX_PACK_08_FOCAL · RELEASE_GATES_PENDING` |
| `SEED-04` | `DeckGenerateScreen` | comandante canônico ganhou seleção e confirmação visual com arte, tipo e identidade de cor | `CODE_SEEN · AUTOMATED_PASS · 3 WEB RELEASE PROFILES_OPENED` | preservar no `UX-PACK-03`; onboarding global no Pack 06 | `RESOLVED_FOR_UX_PACK_03` |
| `SEED-05` | `OnboardingCoreFlowScreen` | intenção progressiva leva a tarefa exata; geração/import/criação concluem somente após sucesso e Home preserva contexto | `CODE_SEEN · AUTOMATED_PASS · 3 WEB RELEASE PROFILES_OPENED` | preservar no `UX-PACK-06`; cross-device exige decisão futura | `RESOLVED_FOR_UX_PACK_06` |
| `SEED-06` | `BattleLiveSpectatorScreen` | mesa, zonas e timeline mostram arte somente para UUID exato publicado; nome sem identidade permanece textual | `CODE_SEEN · AUTOMATED_PASS · 3 WEB RELEASE PROFILES_OPENED` | preservar no `UX-PACK-04`; expansão global no Pack 08 | `RESOLVED_FOR_UX_PACK_04` |
| `SEED-07` | `PostGameNotesScreen` | cartas reais do deck recebem sinal `Preservar/Revisar`, recibo e handoff autenticado para Optimize | `CODE_SEEN · AUTOMATED_PASS · 3 WEB RELEASE PROFILES_OPENED` | preservar no `UX-PACK-04` | `RESOLVED_FOR_UX_PACK_04` |
| `SEED-08` | overlays | 22 checkpoints cobrem open/cancel/error/recovery/final nos overlays de maior risco | `CODE_SEEN · AUTOMATED_PASS · 66 WEB RELEASE PNG_OPENED · CURRENT_DIGEST` | preservar no próximo aggregate; Battle Coach Android continua separado | `RESOLVED_CURRENT_WEB · GLOBAL_PHYSICAL_PENDING` |

## 6. Matriz de jornadas

| # | Jornada | Persona primária | Entrada | Saída de sucesso | Estado |
|---:|---|---|---|---|---|
| 1 | Descobrir comandante/tema | iniciante/brewer | onboarding/home | intenção e próximo passo definidos | `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| 2 | Pesquisar/compreender carta | todas | busca/deck/set | impressão compreendida e ação contextual | `PARTIAL · GAP_CONFIRMED` |
| 3 | Importar/escanear coleção | retornando/colecionador | coleção/import/scanner | lote revisado antes de persistir | `PHASE_1_COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · SCANNER_FLAGGED · ANDROID_PHYSICAL_PENDING` |
| 4 | Corrigir impressão/localização | colecionador/trader | item da coleção | posse exata e localização atualizadas | `PRINTING_IMPLEMENTED · LOCATION_MIGRATION_PENDING` |
| 5 | Criar/gerar/importar deck | iniciante/brewer | home/decks | deck aberto com intenção preservada | `COMPLETE_LOCAL · ONBOARDING_HANDOFF_PROVED` |
| 6 | Construir com cartas livres | brewer | deck/coleção | owned/alocada/livre/faltante coerentes | `PARTIAL · GAP_CONFIRMED` |
| 7 | Interpretar diagnóstico | iniciante/brewer | deck analysis | causa, confiança e ação compreendidas | `EXISTS · GAP_CONFIRMED` |
| 8 | Comparar/aplicar/testar/desfazer | brewer | optimize | diff confirmado, validado e testável | `COMPLETE_FOR_UX_PACK_03_04 · FOCAL_WEB_VISUAL_PASS` |
| 9 | Localizar/negociar faltantes | collector/trader | deck/collection | caminho confiável para resolver faltas | `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| 10 | Compartilhar/receber feedback | social/brewer | deck/community | contexto e mudanças compreensíveis | `CONTEXT_COMPLETE_LOCAL · STRUCTURED_SHARE_PENDING` |
| 11 | Iniciar/retomar/encerrar partida | jogador de mesa | deck/home | sessão coerente e conclusão explícita | `COMPLETE_FOR_UX_PACK_04_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| 12 | Transformar partida em ajuste | jogador de mesa/brewer | pós-jogo/replay | aprendizado retorna ao deck/análise | `COMPLETE_FOR_UX_PACK_04_LOCAL · FOCAL_WEB_VISUAL_PASS` |

## 7. Matriz de funcionalidades

Para cada job relevante, usar exatamente um estado principal e anotar evidência:

- `EXISTS_AND_VISIBLE`;
- `EXISTS_BUT_HIDDEN`;
- `INFORMATION_ONLY`;
- `PARTIAL`;
- `MISSING`;
- `DEFERRED_BY_SCOPE`;
- `NOT_APPLICABLE`;
- `RUNTIME_UNKNOWN`.

| Job/feature | Superfícies | Estado | Evidência | Dor/impacto | Decisão |
|---|---|---|---|---|---|
| Owned / alocada / livre / faltante | deck + collection + binder | `PARTIAL` | busca expõe as quatro leituras; detalhe do deck não | modelo forte, experiência fragmentada | `UX-PACK-02` |
| Recomendação explicável | analyze + optimize | `COMPLETE_FOR_OPTIMIZE · ANALYZE_REMAINDER` | Optimize mostra fontes/shells, antes/depois e motivo/papel/risco/confiança por par; oferta/match social mostra origem, preço e freshness; análise fora da Oficina mantém escopo próprio | confiança/controle no ponto de aplicação | `UX-PACK-03/05` concluídos nos respectivos pontos; Analyze mantém escopo próprio |
| Imagem e impressão correta | cards + collection + trades + perfis | `COMPLETE_FOR_AUTHORIZED_PACKS · CURRENT_P2_FOCAL_PASS · GLOBAL_REANCHOR_PENDING` | identidade compartilhada chegou a busca, deck, Sample Hand, Optimize, Binder, Marketplace, Comunidade, Trades e perfil público; o P2 abriu o recorte afetado sem atribuir printing oficial às fixtures | reconhecimento/preço | preservar nos Packs 01–08 e reancorar o aggregate sem carry-forward |
| Diagnóstico → ação → teste | deck lifecycle | `COMPLETE_FOR_UX_PACK_03_04` | Oficina encaminha para teste; Home/Battle/replay preservam revisão; pós-jogo produz recibo estruturado; Optimize reabre evidência autenticada e mostra o que usou | ciclo de decisão e retorno fica explícito sem prometer aprendizado automático | `UX-PACK-03/04 concluído localmente` |
| Partida → pós-jogo → ajuste | life/battle/retention/deck | `COMPLETE_FOR_UX_PACK_04_LOCAL` | sessão/replay, cartas reais, issues, revisão e `note_id` atravessam; backend revalida usuário/deck/nota antes da recomendação | continuidade do diferencial fechada no escopo focal | `UX-PACK-04`; matriz P0/release permanecem separadas |
| Faltante → proposta → conclusão | deck/community/marketplace/trades | `COMPLETE_FOR_UX_PACK_05_LOCAL` | cópia pública exata, tipo e origem atravessam URL; backend revalida disponibilidade; contraproposta de troca pura é atômica | jornada deixa de terminar em informação sem inferir impressão ou pagamento | `UX-PACK-05`; release e mediação financeira permanecem fora do escopo |
| Feedback contextual | community deck | `COMPLETE_FOR_CONTEXT_LABEL` | comentário novo preserva deck/categoria/carta em envelope compatível; legado continua legível | discussão mantém o objeto sem migration | `UX-PACK-05`; diff/thread estruturado continua futuro |
| Intenção → tarefa → Home | onboarding/home/decks/collection | `COMPLETE_FOR_UX_PACK_06_LOCAL` | objetivo, experiência, formato e método persistem; criação/geração/importação concluem após sucesso; jogar/melhorar exigem deck e entrada reais | primeiro uso deixa de ser formulário genérico e não infere conclusão por deck antigo | `UX-PACK-06`; cross-device permanece decisão futura |

## 8. Matriz de imagem

| Superfície/estado | Objeto visual | Papel da imagem | Rótulo | Fallback | Compacto | Evidência | Ação |
|---|---|---|---|---|---|---|---|
| auth/legal/comercial | nenhum | confiança | `IMAGE_NOT_APPLICABLE` | motivo/ícone | N/A | 219 capturas | manter sóbrio |
| card detail | carta | reconhecimento | `IMAGE_PRESENT_USEFUL` | card back honesto | sim | runtime + captura | preservar |
| deck list | comandante/deck | identidade | `IMAGE_PRESENT_USEFUL` | inconsistente no detalhe | sim | runtime + captura | unificar |
| deck detail/commander | comandante | identidade e decisão | `IMAGE_PRESENT_USEFUL` | referência identificada | sim | runtime corrente `UX-PACK-01` | preservar e ampliar |
| sample hand | cartas | decisão/teste | `IMAGE_PRESENT_USEFUL` | referência identificada | sim | runtime corrente `UX-PACK-01` | preservar |
| set detail | impressão/carta | reconhecimento físico | `IMAGE_PRESENT_USEFUL` | referência identificada | sim | runtime corrente `UX-PACK-01` | preservar |
| collection/binder | impressão/carta | posse e reconhecimento | `IMAGE_PRESENT_USEFUL` | referência identificada; criação e lote recebem impressão explícita com fallback governado | sim | runtime corrente `UX-PACK-01` + 21 focais Web `UX-PACK-02` | preservar; scanner físico ainda pendente |
| generate/import/optimize | comandante e pares add/cut | confirmação | `IMAGE_PRESENT_USEFUL · UX_PACK_03_VISUAL_PASS` | fallback por referência permanece explícito; decklist não infere cópia física | sim | 24 focais Web release abertos em 2026-08-05 | preservar; onboarding global no Pack 06 |
| Battle/replay/post-game | mesa/cartas do deck | posição e aprendizado | `IMAGE_PRESENT_USEFUL · EXACT_ID_ONLY · UX_PACK_04_VISUAL_PASS` | fallback textual honesto sem UUID; card back governado para identidade ausente | sim | 30 focais Web release abertas em 2026-08-05 | preservar; matriz global no Pack 08 |
| comunidade/trades | deck/carta/pessoa | contexto e confiança | `IMAGE_PRESENT_USEFUL · HISTORY_PRESERVED · UX_PACK_05_VISUAL_PASS` | identidade atual explícita; snapshot imutável preserva histórico e sinaliza legado indisponível | sim | 48 focais Web release abertas em 2026-08-06 | preservar arte/printing/pessoa e CTA contextual |
| onboarding/Home contextual | intenção/deck | identidade e progressão | `IMAGE_PRESENT_USEFUL · UX_PACK_06_VISUAL_PASS` | ilustração ManaLoom no fluxo; deck concluído usa identidade real quando disponível e fallback honesto quando ausente | sim | 15 focais Web release abertas em 2026-08-06 | preservar; recomposição wide fechada no Pack 07 |
| Profile e perfil público | jogador/decks/card art | identidade e confiança | `IMAGE_PRESENT_USEFUL · UX_PACK_07_VISUAL_PASS` | rail própria separa pessoa de conta; perfil público usa arte somente com identidade governada | sim | 30 focais Web release abertas em 2026-08-06 | preservar na reancoragem final; fixture não prova printing oficial |

Pontos em que o código já possui infraestrutura de imagem e que exigem inspeção runtime, sem crédito automático: busca/detalhe de carta, lista/detalhe/análise/otimização de deck, seletor de comandante, sample hand, coleção/fichário/marketplace, sets, home, Battle/replays, comunidade/perfil e trades.

## 9. Matriz de modais e fluxo

| Ocorrência | Taxonomia | Frequência | Perde contexto? | Precisa imagem? | Retomável? | Decisão | Finding |
|---|---|---:|---|---|---|---|---|
| excluir conta/deck, revogar sessões, conceder | `SAFETY_CONFIRMATION` | baixa | não, se cancelável | às vezes | não | manter modal; recapturar | `UX-011` |
| condição/idioma/bracket/lista curta | `BOUNDED_PICKER` | média | baixo | printing sim | não | manter sheet/picker | `UX-PACK-01/02` |
| binder item/card quick edit | `QUICK_EDIT` | alta | risco em erro | sim | deve ser | manter se draft persistir | `UX-PACK-02` |
| create deck/import review/optimize longo | `FLOW_WORKSPACE_IMPLEMENTED` | alta | não no escopo comprovado | sim | sim | screens persistentes + preflight e aba Oficina; Optimize mantém modal focado com reader e seleção pareada | `UX-PACK-03 RESOLVED` |
| etapas/fontes da análise | `INLINE_EDUCATION` | média | não | não | N/A | manter accordion inline | sem finding |
| empty/info sem CTA | `DEAD_END_INFO` | alta | contexto termina | depende | N/A | tornar acionável | `UX-013` |
| undo/market primary action | `HIDDEN_PRIMARY_ACTION` | alta | undo não; market ainda sim | não | deve ser | undo persiste na Oficina; market permanece no Pack 05 | `UX-004 aberto / UX-010 resolvido` |
| snackbar com erro/decisão durável | `TRANSIENT_MISUSE` | média | conflito de rollback não; demais superfícies podem | não | deve ser | conflito de otimização já é inline; ampliar por pacote | `UX-010 resolvido / UX-011 aberto` |

## 10. Registro de findings

| ID | Sev. | Onda | Superfície/jornada | Evidência | Problema | Consequência | Causa raiz | Proposta | Confiança | Esforço | Status |
|---|---|---:|---|---|---|---|---|---|---:|---:|---|
| `UX-001` | P1 | 4 | pós-jogo → Optimize | code + 107 app + 46 servidor + 30 focais Web release abertas | app envia `post_game_note_id`; backend reabre nota owner/deck-scoped, canonicaliza cartas e devolve evidência no preview | recomendação mostra problemas e cartas observadas sem copiar nota livre nem autorizar apply | contrato `post_game_optimize_evidence_v1` e revisão na assinatura de cache | `UX-PACK-04` | alta | alta | `RESOLVED_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| `UX-002` | P1 | 2 | coleção | code + automated full local components + 21 focais Web release no aggregate global | workspace em lote, draft, preflight/apply, falha parcial, retry e histórico implementados; scanner usa a mesma fila sob feature flag | cadastro volumoso deixa de exigir uma mutation por modal; a fase Web focal está comprovada | entrada por item e ausência de contrato idempotente | `UX-PACK-02` fase sem migration | alta | alta | `RESOLVED_PHASE_1 · AUTOMATED_FULL_LOCAL_COMPONENTS_PASS · GLOBAL_VISUAL_PASS · SCANNER_PHYSICAL_PENDING` |
| `UX-003` | P1 | 2 | printing/localização | code + ADR 0008 + contrato de ingestão | seleção, Binder, lote e histórico do Trade preservam impressão/estado físico; item existente troca `card_id`; localização estruturada ainda não existe no schema | posse exata de impressão é corrigível sem alegar localização inexistente | mistura anterior entre impressão de catálogo e cópia possuída | `UX-PACK-01` fechado; ingestão no `UX-PACK-02`; localização após autorização de migration | alta | média | `PRINTING_AND_INGESTION_IMPLEMENTED · LOCATION_PENDING` |
| `UX-004` | P1 | 5 | faltante → trade | code + 116 app + 21 servidor + 48 focais Web release abertas | match leva cópia pública exata a proposta recuperável; backend revalida visibilidade e disponibilidade | jornada fecha sem inventar impressão nem depender de `extra` | contrato de rota, identidade jogável/cópia física e revalidação server-side | `UX-PACK-05` | alta | alta | `RESOLVED_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| `UX-005` | P1 | 2–5 | imagens de carta | 214 P0 + 5 Battle Live históricos + 9 Pack 01 + 24 Pack 03 + 30 Pack 04 + 30 Pack 07 abertas | identidade/printing, deck/Optimize, Battle/aprendizado e perfil público usam arte governada; nome sem UUID permanece textual | reconhecimento foi fechado nos destinos autorizados sem inventar identidade ou impressão | contrato visual compartilhado, fallback honesto e política exact-ID | Packs 01/03/04/07 concluídos localmente; fixture determinística não prova printing oficial | alta | média | `RESOLVED_FOR_AUTHORIZED_PACKS · FIXTURE_ART_NOT_PRINTING_PROOF` |
| `UX-006` | P1 | 3 | import de deck | code + automated + 24 focais Web release abertos em 2026-08-05 | preflight read-only mostra identidade jogável reconhecida/localizada, arte, pendências e CTA de rascunho antes da criação; printing física não é inferida no deck | ambiguidade de nome aparece antes da escrita e permanece explícita | criação anterior à revisão | `UX-PACK-03`; impressão física continua sob ADR 0008 | alta | média | `RESOLVED_FOR_PLAYABLE_IDENTITY · PHYSICAL_PRINTING_NOT_CLAIMED` |
| `UX-007` | P1 | 1 | onboarding | code + 86 testes focais + 15 capturas Web release abertas | intenção, contexto e método persistem; criar/gerar/importar concluem só após sucesso e `from=onboarding` é consumido no retorno | primeira tarefa é concreta, retomável e termina em Home contextual sem falsa conclusão | store owner-scoped, handoffs explícitos e rotas endereçáveis | `UX-PACK-06` | alta | média | `RESOLVED_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| `UX-008` | P1 | 4 | Home → Life | code + automated + 30 Pack 04 + 15 Pack 06 focais Web release abertas | Home exige deck/revisão ou modo rápido, preserva sessão e mantém intenção de jogar pendente até abrir a mesa | Life Counter vinculado pode virar recibo pós-jogo; modo sem deck continua honesto | sessão, handoff e onboarding agora carregam contexto explícito | `UX-PACK-04/06` | alta | média | `RESOLVED_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| `UX-009` | P1 | 3/5 | IA/sinergia/fontes | code + automated + 24 Pack 03 + 48 Pack 05 focais Web release abertos | Optimize explicita fontes/impacto; match e oferta mostram origem, preço, disponibilidade e freshness no ponto de decisão | workshop e negociação deixam de parecer score/oferta sem base; análise geral mantém escopo próprio | proveniência aproximada do objeto e da ação | `UX-PACK-03/05` | alta | média | `RESOLVED_FOR_AUTHORIZED_PACKS · ANALYZE_REMAINDER` |
| `UX-010` | P1 | 3 | undo otimização | code + automated + 24 focais Web release abertos em 2026-08-05 | aba Oficina lê histórico owner-scoped, mantém `Desfazer aplicação` no evento e mostra conflito inline após drift | rollback durável permanece encontrável e nunca sobrescreve edição nova | histórico antes sem UI | `UX-PACK-03` | alta | média | `RESOLVED · FAIL_CLOSED_CONFLICT_PROVED` |
| `UX-011` | P1 | 0/7 | prova visual | policy + 55 testes + 66 focais históricas + 66 runtime atuais | 22 estados ligam before/open/error/recovered/final a anchor e teste; Binder recuperado foi reaberto nos três perfis do P2 | recuperação/cancelamento continua coberta sem mutation live; revisão integral atual ainda depende do aggregate | superfície `critical_overlays_states` e três manifests atuais | `UX-PACK-08` | alta | média | `RESOLVED_IMPLEMENTATION · CURRENT_RUNTIME_PASS · P2_FOCAL_VISUAL_PASS · GLOBAL_REANCHOR_PENDING` |
| `UX-012` | P1 | 0/7 | governança | contrato + mapa + policy + 25 manifests atuais | política exige 26 manifests/456 PNGs; 25/402 estão no digest atual e somente o P0 físico 1/54 está stale | 402/402 Web correntes foram revisadas; as 54 físicas são históricas, nenhum crédito antigo foi promovido e o gate recusa review/hashes antigos | igualdade fail-closed, hashes, dimensões e contagens reconciliadas | `UX-PACK-08` | alta | baixa | `RESOLVED_LOGIC · PHYSICAL_AGGREGATE_REANCHOR_PENDING` |
| `UX-013` | P2 | 1/2/5 | empty states | 48 Pack 05 + 15 Pack 06 + 30 Pack 07 focais abertas | primeiro uso, zero resultados, erro, offline e indisponível têm linguagem, motivo e ação próprios nas superfícies autorizadas | becos genéricos foram substituídos por contexto e próxima ação real | composição por job e taxonomia explícita | `UX-PACK-05/06/07` | alta | média | `RESOLVED_FOR_AUTHORIZED_SURFACES · FOCAL_WEB_VISUAL_PASS` |
| `UX-014` | P2 | 7 | Web wide | 30 capturas Pack 07 abertas | Profile, perfil público e primeiro Deck recompõem identidade/tarefa em rail + workspace | 1920×1080 deixa de ser coluna mobile estreita nas superfícies focais | mestre/contexto à esquerda e tarefa à direita | `UX-PACK-07` | alta | média | `RESOLVED_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| `UX-015` | P2 | 5/6 | perfis | 48 Pack 05 + 30 Pack 07 focais abertas | Profile e perfil público mostram identidade, histórico, privacidade e decks; card art aparece com identidade governada | pessoa é apresentada como jogador sem expor localização privada | rails próprias e separação entre identidade e conta/segurança | `UX-PACK-05/07` | alta | média | `RESOLVED_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| `UX-016` | P2 | 6 | quota IA | code + automated + 30 capturas Pack 07 abertas | barra, percentual e copy comunicam exclusivamente ações usadas | leitura rápida e texto seguem o mesmo modelo mental | `used / total`, com restante apenas como dado auxiliar explícito | `UX-PACK-07` | alta | baixa | `RESOLVED_LOCAL · AUTOMATED_PASS` |
| `UX-017` | P2 | 4 | Battle Live | code + automated + 12 focais Battle dos três perfis dentro da matriz de 30 | estado observável, zonas públicas e timeline exibem arte somente para identidade exata; reconnect, timeout e conclusão têm retorno acionável | observar comunica mesa e sequência pública, não apenas progresso de job | cursor público versionado ganhou identidade visual allowlisted | `UX-PACK-04` | alta | alta | `RESOLVED_LOCAL · EXACT_ID_ONLY · FOCAL_WEB_VISUAL_PASS` |
| `UX-018` | P2 | 6 | Profile | code + automated + cinco estados em três viewports | Save desabilitado limpo; dirty, saving, success e error ficam inline e preservam o rascunho | edição e persistência passam a ser explícitas e recuperáveis | baseline do formulário e dock de ação stateful | `UX-PACK-07` | alta | baixa | `RESOLVED_LOCAL · FOCAL_WEB_VISUAL_PASS` |
| `UX-019` | P1 | 0/3 | prova do import de deck | harness/guard + P0 Web corrente | a prova Web corrente retém `1 Sol Ring`, contador e CTA; o guard continua exigindo retenção, detecção e presença no viewport | o aggregate novo não poderá creditar o hint vazio; somente a prova física ainda precisa ser recapturada | entrada controlada por controller, espera do estado e guard de política | manter o guard e recapturar o perfil físico no digest atual | `UX-PACK-08` | alta | baixa | `RESOLVED_IMPLEMENTATION · CURRENT_WEB_REVIEWED · PHYSICAL_REANCHOR_PENDING` |
| `UX-020` | P1 | polish | detalhe de deck mobile | code + teste 390×844 + suíte completa 1525/1525 | as quatro abas usam rolagem somente no breakpoint compacto e preservam `Visão Geral` integralmente | elimina o rótulo ambíguo `Visão Ge` sem esconder conteúdo ou reduzir alvo | `TabBar` antes distribuía largura insuficiente entre quatro rótulos | layout local responsivo com anchors por aba | polish responsivo P1 | alta | baixa | `RESOLVED_LOCAL · AUTOMATED_FULL_PASS · CURRENT_WEB_REVIEWED · PHYSICAL_REANCHOR_PENDING` |
| `UX-021` | P1 | polish | vazios/resultados únicos desktop-wide | code + 21 capturas focais abertas + 239 runtime correntes | `AppStatePanel` usa rail + workspace e Trade usa mestre–detalhe para match único; mobile preserva largura útil | reduz aparência de coluna mobile ampliada e elimina campos comprimidos | composição anterior limitava o conteúdo e não reagia a canvas amplo | workbench proporcional sem conteúdo decorativo inventado | polish responsivo P1 | alta | baixa | `RESOLVED_LOCAL · AUTOMATED_FULL_PASS · FOCAL_WEB_VISUAL_PASS · GLOBAL_REANCHOR_PENDING` |
| `UX-022` | P2 | polish | cartas/printings/evidências horizontais | code + testes + 12 capturas focais abertas | rail compartilhado mostra instrução e ação de continuidade fora da arte; Sample Hand mostra posição `x de 7` | o usuário descobre conteúdo lateral sem depender de um item cortado e sem perder informação da carta | carrosséis anteriores dependiam de gesto implícito ou corte parcial | `HorizontalDiscoveryRail`, controle de 48 px, semântica e reduced motion | polish responsivo P2 | alta | baixa | `RESOLVED_LOCAL · AUTOMATED_FULL_PASS · FOCAL_WEB_VISUAL_PASS` |
| `UX-023` | P2 | polish | nomes longos em Profile/perfil público | code + testes semânticos + 6 capturas focais abertas | nome usa até duas linhas e elipse visual; semântica/tooltip preservam a identidade integral | identidade longa deixa de comprimir ou quebrar a rail sem ser truncada para tecnologia assistiva | exemplos curtos e regras locais divergentes mascaravam o caso real | `PlayerIdentityName` compartilhado | polish responsivo P2 | alta | baixa | `RESOLVED_LOCAL · AUTOMATED_FULL_PASS · FOCAL_WEB_VISUAL_PASS` |
| `UX-024` | P2 | polish | qualidade das fixtures Deck/Battle | harness + arte same-origin + checkpoints reais | comandante aparece com CTA pai; mão inicial tem 99 cartas de origem/7 visíveis; evidências usam imagens e rótulos distintos | a prova deixa de validar conteúdo artificial ou imagens duplicadas como se fossem estados reais | fixtures anteriores eram curtas, repetidas ou usavam rótulos de placeholder | fixtures determinísticas distintas, sem crédito de printing oficial | polish responsivo P2 | alta | baixa | `RESOLVED_LOCAL · AUTOMATED_FULL_PASS · FOCAL_WEB_VISUAL_PASS · FIXTURE_ART_NOT_PRINTING_PROOF` |
| `UX-025` | P2 | governança | Legal/Privacy | source + `14/14` testes de responsividade/deep link/200%/consentimento | largura de leitura, versões, navegação e seções sóbrias estão adequadas; nenhuma arte decorativa foi adicionada | conteúdo permanece legível e confiável sem confundir acabamento visual com validade jurídica | revisão de UI e revisão jurídica eram tratadas como uma única pendência | manter composição; concluir prova física/humana e, por último, submeter copy/contratos a profissional jurídico | polish responsivo P2 | alta | baixa | `UI_COMPOSITION_COMPLETE_LOCAL · AUTOMATED_PASS · CURRENT_WEB_REVIEWED · PHYSICAL_HUMAN_GATES_PENDING · COUNSEL_SIGNOFF_LAST` |

## 11. Pacotes de execução

Um pacote só fica `READY_FOR_IMPLEMENTATION` quando contém:

- finding(s) confirmado(s) e evidência;
- pessoa, job e jornada afetados;
- tese de conteúdo, visual e interação;
- wireflow antes/depois;
- telas, componentes, estados, rotas e APIs impactados;
- exigência de imagens/assets e direitos/fonte;
- cópia proposta em PT-BR;
- critérios de aceite automatizados, runtime e visuais;
- riscos, dependências, não objetivos e rollback;
- decisão humana que autorizou a onda.

| Pacote | Onda | Findings | Estado | Autorização | Implementação |
|---|---:|---|---|---|---|
| `UX-PACK-01` | 2 | `UX-003`, `UX-005` | `COMPLETE · GLOBAL_P0_PASS · UX_019_RESOLVED` | 2026-08-03, “do que montou e organizou comece”; 2026-08-05, “pode fazer” | concluída; sem autorização de release ou de outro pacote |
| `UX-PACK-02` | 2 | `UX-002`, `UX-003` | `PHASE_1_COMPLETE_LOCAL · CURRENT_RUNTIME_PASS · HISTORICAL_GLOBAL_PASS · LOCATION_PENDING` | 2026-08-05, “pode seguir para os proximos passos” | fase sem migration concluída localmente; migration e release não autorizados |
| `UX-PACK-03` | 3 | `UX-006`, `UX-007`, `UX-009`, `UX-010` | `COMPLETE_LOCAL · CURRENT_RUNTIME_PASS · P2_FOCAL_VISUAL_PASS · HISTORICAL_GLOBAL_PASS` | 2026-08-05, “okay então pode prosseguir” após confirmação de evolução visual | concluída localmente; onboarding global permanece no Pack 06; sem migration, release, commit ou push |
| `UX-PACK-04` | 4 | `UX-001`, `UX-008`, `UX-017` | `COMPLETE_LOCAL · CURRENT_RUNTIME_PASS · P2_FOCAL_VISUAL_PASS · HISTORICAL_GLOBAL_PASS` | 2026-08-05, “okay então pode prosseguir” e “continue” | concluída localmente; sem migration, release, commit, push ou promoção de aprendizado do motor |
| `UX-PACK-05` | 5 | `UX-004`, `UX-009`, `UX-013`, `UX-015` | `COMPLETE_LOCAL · CURRENT_RUNTIME_PASS · HISTORICAL_GLOBAL_PASS` | 2026-08-06, “pode seguir para os proximos passos”, “continue” e “okay continue” | concluída; sem migration, release, commit, push ou mediação financeira |
| `UX-PACK-06` | 1 | `UX-007`, `UX-008`, `UX-013` | `COMPLETE_LOCAL · CURRENT_RUNTIME_PASS · HISTORICAL_GLOBAL_PASS` | 2026-08-06, “continue” | concluída; sem contrato cross-device, migration, release, commit ou push |
| `UX-PACK-07` | 7 | `UX-005`, `UX-013`–`UX-016`, `UX-018` | `COMPLETE_LOCAL · CURRENT_RUNTIME_PASS · P2_FOCAL_VISUAL_PASS · HISTORICAL_GLOBAL_PASS` | 2026-08-06, continuações explícitas até “continue” | concluída; sem migration, release, commit ou push |
| `UX-PACK-08` | 0/7 | `UX-011`, `UX-012`, `UX-019` | `COMPLETE_LOCAL · CURRENT_RUNTIME_PASS · CURRENT_WEB_402_VISUAL_REVIEWED · PHYSICAL_54_STALE · CURRENT_AGGREGATE_STALE` | 2026-08-06–07, continuações explícitas | concluída localmente; Samsung físico, aggregate e gates humanos vêm antes do parecer jurídico externo assinado |
| `POLISH-RESPONSIVO-P1` | polish | `UX-020`, `UX-021` | `COMPLETE_LOCAL · AUTOMATED_FULL_PASS · FOCAL_WEB_VISUAL_PASS · GLOBAL_REANCHOR_INCOMPLETE` | 2026-08-06, “continue” | duas dívidas P1 implementadas; os três P0 Web já foram recapturados e o perfil físico continua pendente |
| `POLISH-RESPONSIVO-P2` | polish | `UX-022`–`UX-025` | `COMPLETE_LOCAL · AUTOMATED_FULL_PASS · PASS_RUNTIME_25_MANIFESTS_402_SCREENSHOTS · CURRENT_WEB_402_VISUAL_REVIEWED · OFFICIAL_LEGAL_RESEARCH_COMPLETE · COUNSEL_SIGNOFF_LAST` | 2026-08-07, “continue” | affordance horizontal, nomes longos e fixtures fechados; briefing jurídico pronto; Samsung físico, aggregate e gates humanos vêm antes do parecer assinado |

## 12. Log de evidência da rodada

| Data/hora | SHA/digest | Plataforma | Comando/ação | Resultado | Artefato | Aberto/revisado por |
|---|---|---|---|---|---|---|
| `2026-08-03T13:37:31Z` | `95afa75b8` / UI `3b20f724…` | Web mobile/desktop/wide + Android emulador + Battle Live Web | abrir e revisar o aggregate corrente | 219/219 imagens abertas; escopo declarado `PASS` | `docs/qa/ui-live/latest.json` | Codex, inspeção visual assistida |
| `2026-08-03` | `95afa75b8` / UI `3b20f724…` | gates locais | `manaloom_ui_live_evidence_gate --check`, `quality_gate ui-proof`, `quality_gate ui-audit` | `PASS`; analyzer sem issues; 53 testes de UI aprovados | saída local dos gates + manifests correntes | Codex |
| `2026-08-03T14:19:46Z` | `95afa75b8` / UI `3b20f724…` | build Web real + PostgreSQL/API loopback | percorrer rotas e jornadas autenticadas | runtime exercitado; gaps confirmados e documentados | fixture descartável de QA | Codex via navegador no app |
| `2026-08-03T15:00:53Z` | `95afa75b8` / manifesto `af4ce1b4…` | cleanup | encerrar fixture e validar resíduos | banco 0; listeners Web 0; listeners API 0; credenciais removidas | `cleanup-summary.json` da execução `20260803T141946Z_44035_7767` | Codex |
| `2026-08-03T21:13:49Z` | UI `eef339fc…` | Web release 390×844 + PostgreSQL/API loopback | provar a fundação de identidade/printing do `UX-PACK-01` | 22/22 capturas abertas; quatro manifests `PASS_RUNTIME`; revisão visual focal aprovada | `docs/qa/ui-live/current/ux-pack-01-*` | Codex, inspeção visual assistida |
| `2026-08-03` | UI `eef339fc…` | Flutter 3.44.6 fixado | suíte focal + análise estática | 57/57 testes; 17 arquivos sem issues | saída local + relatório `UX-PACK-01` | Codex |
| `2026-08-03` | UI `eef339fc…` | gates locais | `quality_gate ui-audit` e `quality_gate ui-proof` | análise + 53/53 testes amplos aprovados; gates recusam somente review/capturas globais no digest antigo `9a6f4dec…` | fail-closed esperado; recaptura integral pendente | Codex |
| `2026-08-03` | execução `20260803T204510Z_75831_21824` | cleanup | encerrar fixture isolada do `UX-PACK-01` | banco 0; listeners Web 0; listeners API 0; credenciais removidas | `cleanup-summary.json` da execução | Codex |
| `2026-08-05T10:38:06Z` | UI `48fbe279…` | Chrome 150 Web release 390×844 + PostgreSQL/API loopback | exercer Sample Hand, Optimize, Binder, Marketplace e Trades | 8/8 capturas íntegras e abertas; `PASS_RUNTIME · PASS_VISUAL_REVIEWED` focal | `docs/qa/ui-live/current/ux-pack-01-completion-web/capture-manifest.json` | Codex, inspeção visual de cada PNG |
| `2026-08-05` | UI `48fbe279…` | Flutter/Dart 3.44.6 fixado | suíte focal e analisadores completos | 225/225 Flutter; 12/12 servidor; app e servidor sem issues | saída local + relatório `UX-PACK-01` | Codex |
| `2026-08-05` | UI `48fbe279…` | gates locais | `quality_gate ui-audit` e `quality_gate ui-proof` | analyzer + 53/53 UI aprovados; ambos recusam somente review global e cinco captures stale | fail-closed esperado; recaptura global pendente | Codex |
| `2026-08-05` | execução `20260805T100604Z_58018_10331` | cleanup | encerrar fixture isolada da continuação | banco 0; listeners Web/API 0; credenciais removidas | `cleanup-summary.json` da execução | Codex |
| `2026-08-05T11:49:59Z` | UI `6efb9f15…` | Chrome 150 Web release 390×844 + PostgreSQL/API loopback | exercer criação/edição do Binder, Sample Hand, Optimize, Marketplace e Trades | 9/9 capturas íntegras, abertas e aprovadas; `PASS_RUNTIME · PASS_VISUAL_REVIEWED` focal | `docs/qa/ui-live/current/ux-pack-01-completion-web/capture-manifest.json` | Codex, inspeção visual de cada PNG |
| `2026-08-05` | UI `6efb9f15…` | Flutter/Dart 3.44.6 fixado + PostgreSQL descartável | suítes focais/completas, analisadores, schema e release ops | 35/35 Flutter focal; 57/57 servidor focal; 1444 app + 1 skip; 2178 servidor; analyzers limpos; schema 79 tabelas/6 views/98 FKs/58 migrations; release ops 27/27 | saída local + relatório `UX-PACK-01` | Codex |
| `2026-08-05` | execução `20260805T114105Z_33711_11651` | cleanup | encerrar fixture isolada com o fluxo real de criação do Binder | banco 0; listeners Web/API 0; credenciais removidas | `cleanup-summary.json` da execução | Codex |
| `2026-08-05T12:05:02Z` | migration `058` | API real + PostgreSQL loopback descartável, sem egress externo | executar `social_trading_live_test.dart` | 2/2 aprovados; editar/remover item do Binder não alterou nem apagou o snapshot do Trade | `manaloom_server_contract_e2e_20260805T120502Z_51147/summary.txt` | Codex |
| `2026-08-05` | UI `6efb9f15…` | gates locais | `quality_gate ui-audit` e `quality_gate ui-proof` | analyzer e 53/53 UI aprovados; ambos recusam corretamente um review global e cinco capturas stale | fail-closed esperado; matriz global não foi promovida | Codex |
| `2026-08-05` | UI `6682d6de…` | Flutter/Dart 3.44.6 fixado + PostgreSQL descartável | validação final de imagem, deck, Binder/Trade, suítes completas, analyzers, schema, project logic e release ops | 16/16 imagem; 44/44 acabamento/carta/deck/Binder/Trade; 56/56 deck; 1458 app + 1 skip; 752 servidor + 3 skips; analyzers limpos; schema 79 tabelas/6 views/98 FKs/58 migrations; release ops 27/27 | saída local; digest lógico `2c74867c…` | Codex |
| `2026-08-05` | UI `6682d6de…` | Chrome 150 Web release 390×844, 1440×900 e 1920×1080 + PostgreSQL/API loopback | recapturar a matriz P0 Web e abrir cada PNG | 54/54 mobile + 53/53 desktop + 53/53 wide em `PASS_RUNTIME`; 160/160 abertas; nenhum defeito estrutural bloqueante; aggregate não promovido sem Android físico | `app/test/ui/goldens/runtime/web_*`; logs da execução `20260805T125923Z_93388_12182` | Codex, inspeção visual de cada PNG |
| `2026-08-05T13:31:40Z` | UI `6682d6de…` | Battle Live Web 1440×900 | recapturar waiting, feed ativo, reconnect, timeout e replay concluído | 5/5 em `PASS_RUNTIME`; 5/5 abertas; timeline continua textual e sem arte de carta | `docs/qa/ui-live/current/battle-live-web/capture-manifest.json` | Codex, inspeção visual de cada PNG |
| `2026-08-05` | UI `6682d6de…` | Samsung SM-A135M físico, Android 14 | três tentativas governadas iniciais do perfil físico | uma tentativa perdeu a surface para outro app; uma atingiu 54 checkpoints, mas o host ficou sem espaço ao gravar a resposta; outra foi cancelada quando `br.com.predador.app` retomou o foco. Nenhum source foi alterado para mascarar o conflito | logs `p0-android-physical*.log` da execução `20260805T125923Z_93388_12182` | histórico de tentativas, sem crédito |
| `2026-08-05T13:51:37Z` | UI `6682d6de…` | Samsung SM-A135M físico, Android 14, 1080×2408 | repetir o perfil governado em janela livre do aparelho | `54/54 · PASS_RUNTIME`; Life Counter nativo capturado em landscape; 54/54 PNGs abertos; nenhum bloqueio estrutural; `deck_import_detected` não exibe o estado detectado e bloqueia promoção visual agregada | `app/test/ui/goldens/runtime/android_physical`; `docs/qa/ui-live/current/p0-matrix/android_physical_sm_a135m.json`; log `p0-android-physical-final.log` | Codex, inspeção visual de cada PNG |
| `2026-08-05T13:57:02Z` | UI `6682d6de…` | matriz P0 Web + Android físico | indexar quatro perfis correntes e executar `quality_gate.sh ui-proof` | manifests `PASS_RUNTIME` com 54/53/53/54 capturas; o manifesto antigo do emulador saiu somente de `current` e continua recuperável no Git; o gate recusou corretamente `latest.json` stale e hashes sem a revisão física; nenhum `PASS_VISUAL_REVIEWED` global foi forçado | `docs/qa/ui-live/current/p0-matrix/*.json` | Codex |
| `2026-08-05` | execução `20260805T125923Z_93388_12182` | cleanup | encerrar fixture loopback após a recaptura global | banco 0; listeners Web/API 0; credenciais removidas; trap encerrou com `original_exit_code=130` por interrupção controlada | `cleanup-summary.json` da execução | Codex |
| `2026-08-05T15:02:03Z` | UI `a98701fb…` | Web 390×844, 1440×900 e 1920×1080 + Samsung SM-A135M físico | corrigir o harness `deck_import_detected`, recapturar e abrir os quatro perfis P0 | 54/53/53/54 em `PASS_RUNTIME`; 214/214 imagens abertas; `1 Sol Ring`, contador detectado e CTA visíveis nos quatro perfis; `UX-019 RESOLVED` | `docs/qa/ui-live/current/p0-matrix/*.json`; testes do harness/guard | Codex, inspeção visual de cada PNG |
| `2026-08-05T15:02:03Z` | UI `a98701fb…` | matriz P0 + Battle Live Web | compor hashes e verificar `latest.json`, `ui-proof` e `ui-audit` | aggregate `PASS`; `PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED`; 219/219 capturas; analyzer limpo e 53/53 testes do audit | `docs/qa/ui-live/latest.json`; cinco manifests correntes | Codex |
| `2026-08-05` | execução `20260805T142318Z_62922_9437` | cleanup | encerrar fixture loopback do reparo `UX-019` | banco 0; listeners Web/API 0; credenciais removidas; `original_exit_code=130` por interrupção controlada | `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_visual_qa/20260805T142318Z_62922_9437/cleanup-summary.json` | Codex |
| `2026-08-05T16:15:51Z` | UI `4f0194c3…` | Web 390×844, 1440×900 e 1920×1080 + Samsung SM-A135M físico + Battle Live Web | abrir individualmente a recaptura final e reancorar o aggregate aos cinco manifests correntes | 214/214 P0 + 5/5 Battle Live abertas; `PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED`; nenhum finding visual bloqueante | `docs/qa/ui-live/latest.json`; cinco manifests correntes | Codex, inspeção visual de cada PNG |
| `2026-08-05` | UI `4f0194c3…` | Flutter/Dart 3.44.6 fixado + gates locais | executar suítes completas, `ui-proof` e `ui-audit` | app 1461 + 1 skip; servidor 752 + 3 skips; `ui-proof` PASS; analyzer e 53/53 no `ui-audit`; guard de callers/`art_crop` aprovado | saída local + relatório `UX-PACK-01` | Codex |
| `2026-08-05` | execução `20260805T153915Z_13435_11917` | cleanup | encerrar fixture loopback da recaptura final | banco 0; listeners Web/API 0; credenciais removidas; `original_exit_code=130` por interrupção controlada | `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_visual_qa/20260805T153915Z_13435_11917/cleanup-summary.json` | Codex |
| `2026-08-05T18:29:42Z` | UI `3bf0cbbd…` | Chrome 150 Web release 390×844, 1440×900 e 1920×1080; API/draft em memória, sem PostgreSQL | exercer fonte, duplicata, impressão, plano, cancelamento, falha parcial, retry e histórico do `UX-PACK-02` | 7/7 por perfil em `PASS_RUNTIME`; 21/21 PNGs abertos; três manifestos em `PASS_VISUAL_REVIEWED`; barra que cobria o workspace e checkpoint de histórico insuficiente foram corrigidos antes do crédito | `docs/qa/ui-live/current/ux-pack-02-collection-import-web-*` | Codex, inspeção visual de cada PNG |
| `2026-08-05T18:57:29Z` | UI `3bf0cbbd…` | Flutter/Dart 3.44.6 fixado + Node 26 para Web | validar componentes locais completos, Web público, performance, hashes e project logic | servidor 44 lotes; analyzer sem issues; app 1472 + 1 skip; Web lint/build/audit/smoke PASS com 0 vulnerabilidades; performance 17 Python + 2 servidor + 3 Flutter; 8 artefatos sincronizados; Node 20.11.1 registrado como toolchain incompatível, sem relabel de falha de produto | saída local + relatório `UX-PACK-02` | Codex |
| `2026-08-05T23:11:27Z–23:13:56Z` | UI `93009fc2…` | Chrome 150 Web release 390×844, 1440×900 e 1920×1080; gateways/draft em memória, sem PostgreSQL | exercer Home, sessão pausada, Battle Live, reconnect, timeout, conclusão, replay, pós-jogo e Optimize do `UX-PACK-04` sob perfis exclusivos governados | 10/10 por perfil em `PASS_RUNTIME`; 30/30 PNGs abertos com arte same-origin; `PASS_VISUAL_REVIEWED` focal; zero entrada proibida nos consoles | `docs/qa/ui-live/current/ux-pack-04-battle-learning-web-*` | Codex, inspeção visual de cada PNG |
| `2026-08-05` | UI `93009fc2…` | Flutter/Dart 3.44.6 fixado | validar contratos focais de sessão, cursor público, replay, pós-jogo, handoff autenticado e governança visual do Optimize | focais app `107/107` e servidor `46/46`; completas app `1489 + 1 skip` e servidor `752 + 3 skips`; analyzers, harness, política e inventário aprovados | saída local + relatório `UX-PACK-04` | Codex |
| `2026-08-05` | UI `93009fc2…` | gate local de evidência | executar `quality_gate.sh ui-proof` sem promover evidência antiga | `FAIL-CLOSED` esperado: review + cinco manifests globais stale e nove perfis focais dos UX-PACK-02/03/04 ainda ausentes do aggregate; nenhum PASS global forçado | `docs/qa/ui-live/latest.json`; relatório `UX-PACK-04` | Codex |
| `2026-08-06T00:22:19Z` | UI `93009fc2…` | Web 390×844, 1440×900 e 1920×1080 + Samsung SM-A135M físico + quatro jornadas focais Web release | reabrir toda a matriz corrente, reconciliar bytes/dimensões/SHA e compor o aggregate exigido pela política | 14/14 manifests e 294/294 capturas; `PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED`; nenhum finding visual bloqueante | `docs/qa/ui-live/latest.json`; `MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md` | Codex, inspeção visual individual de cada PNG |
| `2026-08-06T12:41:57Z–12:44:52Z` | UI `70322d07…` | Chrome 150 Web release 390×844, 1440×900 e 1920×1080; gateways em memória | exercer matches, Marketplace, proposta reidratada/revisão/indisponibilidade, contraproposta, recusa, erro, conclusão, vazios e comentário contextual | 16/16 por perfil em `PASS_RUNTIME`; a primeira captura mobile foi recusada por largura espremida, corrigida por constraints locais e toda a matriz foi recapturada; `48/48 PASS_VISUAL_REVIEWED` | `docs/qa/ui-live/current/ux-pack-05-social-trade-web-*`; relatório `UX-PACK-05` | Codex, inspeção visual individual de cada PNG |
| `2026-08-06` | UI `70322d07…` | Flutter/Dart 3.44.6 fixado | validar social, trades, mensagens, collection/Binder, rotas, política e contratos server-side | `116/116` Flutter e `21/21` servidor; regressão de largura local, deep link, disponibilidade, privacidade, contraproposta atômica e comentário contextual aprovados | saída local + `MANALOOM_UX_PACK_05_IMPLEMENTATION_2026-08-06.md` | Codex |
| `2026-08-06` | UI `70322d07…` | gate local de evidência | executar `./scripts/quality_gate.sh ui-proof` sem promover o aggregate anterior | `FAIL-CLOSED` esperado: review + 14 manifests globais stale e três perfis `web_social_trade_*` ausentes de `latest.json`; nenhum crédito antigo foi reaproveitado | `docs/qa/ui-live/latest.json`; relatório `UX-PACK-05` | Codex |
| `2026-08-06` | UI `70322d07…` | preflight read-only de reancoragem global | consultar ADB e capacidade do host antes de iniciar 342 recapturas | somente `emulator-5554` disponível; perfil físico obrigatório ausente; 5,6 GiB livres. Reancoragem não iniciada e nenhum emulador foi rotulado como físico | política de evidência + relatório `UX-PACK-05` | Codex |
| `2026-08-06T14:16:47Z` | UI `5df01bcd…` | Chrome 150 Web release 390×844, 1440×900 e 1920×1080; stores/gateways em memória | exercer primeiro uso, caminho de montagem, retomada, skip/Home e conclusão/Home do `UX-PACK-06` | `5/5` por perfil em `PASS_RUNTIME`; a revisão intermediária refinou helper e retomada antes da recaptura final; `15/15 PASS_VISUAL_REVIEWED`; zero entrada proibida nos consoles | `docs/qa/ui-live/current/ux-pack-06-onboarding-intent-web-*`; relatório `UX-PACK-06` | Codex, inspeção visual individual de cada PNG |
| `2026-08-06` | UI `5df01bcd…` | Flutter/Dart 3.44.6 fixado | validar onboarding, Home, store, autenticação, geração/importação/criação, Binder e política | `86/86 PASS`; handoffs somente após sucesso, owner scope, skip/resume, falha/retry, teclado, 200% e responsividade aprovados | saída local + `MANALOOM_UX_PACK_06_IMPLEMENTATION_2026-08-06.md` | Codex |
| `2026-08-06` | UI `5df01bcd…` | gates lógicos e de evidência | executar `manaloom_project_logic --write/--check` e `quality_gate.sh ui-proof` sem promover o aggregate anterior | lógica sincronizada; `ui-proof` em `FAIL-CLOSED` esperado porque review + 14 manifests estão stale e seis perfis Social/Trade + Onboarding não pertencem a `latest.json` | `project_logic_manifest.json`, `docs/generated/*`, `docs/qa/ui-live/latest.json` e relatório `UX-PACK-06` | Codex |
| `2026-08-06T15:44:58Z` | UI `a408c2a3…` | Chrome 150 Web release 390×844, 1440×900 e 1920×1080; providers/gateways em memória | exercer Profile clean/dirty/saving/error/saved, perfil público com card art, primeiro deck e estados sem resultado/offline/indisponível | `10/10` por perfil em `PASS_RUNTIME`; `30/30 PASS_VISUAL_REVIEWED` após abertura individual em resolução original; zero entrada proibida nos consoles | `docs/qa/ui-live/current/ux-pack-07-visual-system-web-*`; relatório `UX-PACK-07` | Codex, inspeção visual individual de cada PNG |
| `2026-08-06` | UI `a408c2a3…` | Flutter/Dart 3.44.6 fixado | validar estados, quota, Profile, perfil público, Decks, copy e política | `44/44 PASS`; analyzer e harness focal aprovados; a política passou a exigir 23 manifests/387 capturas naquele ponto | saída local + `MANALOOM_UX_PACK_07_IMPLEMENTATION_2026-08-06.md` | Codex |
| `2026-08-06` | UI `a408c2a3…` | gates lógicos e de evidência | executar project logic, validar três diretórios focais e rodar `quality_gate.sh ui-proof` | oito artefatos sincronizados; `10/10` PNGs íntegros por perfil; `ui-proof` em `FAIL-CLOSED` esperado porque review + 14 manifests estão stale e nove perfis dos Packs 05–07 faltam no aggregate; nenhum PASS global forçado | `project_logic_manifest.json`, `docs/generated/*`, `docs/qa/ui-live/latest.json` e relatório `UX-PACK-07` | Codex |
| `2026-08-06T17:33:29Z–17:37:17Z` | UI `60bbef19…` | Chrome 150 Web release 390×844, 1440×900 e 1920×1080; providers/gateways em memória | exercer 22 checkpoints de Profile/security, Decks/Commander, Fichário, Trade e estados transversais por perfil | `22/22` por perfil em `PASS_RUNTIME`; seletor excessivamente alto e snackbar duplicado foram recusados, corrigidos e toda a matriz foi recapturada; `66/66 PASS_VISUAL_REVIEWED`; zero entrada proibida nos consoles | `docs/qa/ui-live/current/ux-pack-08-critical-overlays-web-*`; relatório `UX-PACK-08` | Codex, inspeção visual individual de cada PNG |
| `2026-08-06` | UI `60bbef19…` | Flutter/Dart 3.44.6 fixado | validar Profile, Decks, Fichário, Trade, estados e política executável | analyzer focal sem issues; `55/55 PASS`; harness controlado aprovado; manifests com 22 PNGs íntegros cada | saída local + `MANALOOM_UX_PACK_08_IMPLEMENTATION_2026-08-06.md` | Codex |
| `2026-08-06` | UI `60bbef19…` | gates lógicos e de evidência | executar project logic, revalidar os três diretórios focais e rodar `quality_gate.sh ui-proof` sem promover o aggregate | oito artefatos sincronizados; `22/22` PNGs íntegros por perfil; `ui-proof` em `FAIL-CLOSED` esperado porque review + 14 manifests estão stale e 12 perfis Web dos Packs 05–08 faltam no aggregate; nenhum PASS global forçado | `project_logic_manifest.json`, `docs/generated/*`, `docs/qa/ui-live/latest.json` e relatório `UX-PACK-08` | Codex |
| `2026-08-06T19:55:31Z` | UI `f45f96e3…` | Chrome 150 Web release 390×844, 1440×900 e 1920×1080 + Samsung SM-A135M físico + Battle Live | recapturar e abrir integralmente P0, Battle Live e UX-PACKs 02–08 no mesmo digest | `26/26` manifests, `453/453` PNGs abertos e reconciliados por bytes/dimensão/SHA; `PASS_AUTOMATED · PASS_RUNTIME · PASS_VISUAL_REVIEWED`; zero blocker, oito follow-ups explícitos | `docs/qa/ui-live/latest.json`; `MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md` | Codex, inspeção visual individual de cada PNG |
| `2026-08-06` | UI `f45f96e3…` | gates finais locais | executar project logic, evidence gate, `ui-proof` e `ui-audit`; reconciliar goldens comerciais com a quota por ações usadas | project logic `8/8` sincronizado; evidence gate e `ui-proof` PASS; primeira auditoria encontrou dois baselines comerciais antigos, ambos foram regenerados e abertos; repetição com analyzer limpo, `56/56` testes e `ui-proof` PASS | saída local; dois goldens comerciais; aggregate e relatório global | Codex |
| `2026-08-06T21:08:47Z` | UI `186df24a…` | Flutter 3.44.6 + Chrome 150 Web release 390×844, 1440×900 e 1920×1080 | implementar e validar abas mobile, estados com pouco conteúdo e match único de Trade | analyzer focal limpo; `27/27` testes; 12/12 checkpoints afetados abertos sem campo estreito, overflow ou perda de CTA | `MANALOOM_UX_POLISH_RESPONSIVE_P1_IMPLEMENTATION_2026-08-06.md`; manifests Social/Trade e Visual System | Codex, sem subagentes |
| `2026-08-06T21:08:47Z` | UI `186df24a…` | Battle Live + UX-PACKs 02–08 | recapturar os packs determinísticos permitidos no digest novo | `22/22` manifests e `239/239` PNGs em `PASS_RUNTIME`; P0 `4/214` permanece stale; aggregate global não promovido | `docs/qa/ui-live/current`; `docs/qa/ui-live/latest.json` permanece no digest anterior | Codex; PostgreSQL, Hermes e SQLite não tocados |
| `2026-08-06T22:15:04Z` | UI `df8c3371…` | Flutter/Dart 3.44.6 + Node 26 | fechar as regressões globais encontradas pelo gate e repetir validação completa | analyzer focal limpo; `37/37` focais; Flutter `1525 PASS + 1 skip`; `quality_gate.sh full` PASS incluindo backend, Web público, audit, smoke e harnesses; project logic `8/8` sincronizado | saída local + relatório do polish responsivo P1 | Codex, sem subagentes |
| `2026-08-06T22:15:04Z` | UI `df8c3371…` | Chrome 150 Web release 390×844, 1440×900 e 1920×1080 | recapturar Battle Live e UX-PACKs 02–08 e revisar o recorte afetado | `22/22` manifests, `239/239` PNGs `PASS_RUNTIME`; 21 checkpoints focais abertos sem blocker; `ui-audit` `56/56` antes de `ui-proof` manter `FAIL-CLOSED` pelo P0 `4/214` e review stale | `docs/qa/ui-live/current`; `docs/qa/ui-live/latest.json`; relatório do P1 | Codex; nenhuma escrita PostgreSQL/Hermes/SQLite |
| `2026-08-07` | UI `ebacfe42…` | Flutter/Dart 3.44.6 + Node 26 | implementar rails de descoberta, nomes longos, fixtures e auditar Legal/Privacy | focais `28/28` e `20/20`; Flutter `1527 PASS + 1 skip`; `quality_gate.sh full` PASS; project logic `8/8`; `ui-audit` analyzer + `56/56` antes do fail-closed esperado | `MANALOOM_UX_POLISH_RESPONSIVE_P2_IMPLEMENTATION_2026-08-07.md`; saída local | Codex, sem subagentes |
| `2026-08-07` | UI `ebacfe42…` | Chrome 151 Web release 390×844, 1440×900 e 1920×1080 | recapturar Battle Live e UX-PACKs 02–08; abrir o recorte diretamente afetado | `22/22` manifests e `242/242` PNGs em `PASS_RUNTIME`; 21 capturas focais abertas sem blocker; evidence gate mantém `FAIL-CLOSED` apenas pelo review/aggregate e P0 `4/214` stale | `docs/qa/ui-live/current`; `docs/qa/ui-live/latest.json`; relatório do P2 | Codex; nenhuma escrita PostgreSQL/Hermes/SQLite |
| `2026-08-07` | UI `c25eb28b…` | PostgreSQL/API/Web exclusivamente loopback + Chrome 151 | recapturar a matriz P0 autenticada autorizada depois dos últimos ajustes | Web mobile `54/54`, desktop `53/53` e wide `53/53` em `PASS_RUNTIME`; Samsung SM-A135M ausente, sem substituição por emulador; fixture encerrada com banco/portas/credenciais removidos | `docs/qa/ui-live/current/p0-matrix`; `MANALOOM_P0_GLOBAL_REANCHOR_CONTINUATION_2026-08-07.md` | Codex, sem subagentes |
| `2026-08-07` | UI `c25eb28b…` | 25 manifests Web / 402 capturas correntes + 1/54 físico histórico | revisar e reconciliar a matriz aplicável | `402/402` Web cobertas: 129 novas/alteradas reabertas individualmente e 273 byte a byte idênticas a imagens já abertas na mesma auditoria; 402 caminhos únicos, zero missing e zero divergência de SHA, bytes ou dimensão; físico histórico permaneceu stale e sem crédito | `MANALOOM_P0_GLOBAL_REANCHOR_CONTINUATION_2026-08-07.md` | Codex, inspeção visual individual e reconciliação byte a byte |
| `2026-08-07` | UI `c25eb28b…` | gates locais | executar analyzer/testes de `ui-audit`, evidence gate, `ui-proof` e `ui-audit` | analyzer limpo e `56/56` testes PASS; os três gates de evidência permanecem `FAIL-CLOSED` somente pelo digest/review físico stale, hashes do aggregate antigo e contagem antiga; nenhuma falha de integridade nos 402 PNGs Web | saída local; `docs/qa/ui-live/latest.json` preservado | Codex |
| `2026-08-07` | fontes oficiais vigentes | LGPD, ECA Digital, Marco Civil, CDC, ANPD, Wizards e Scryfall | preparar revisão jurídica externa | pesquisa oficial completa e briefing P0/P1 pronto; parecer de profissional habilitado e lançamento comercial continuam bloqueados | `MANALOOM_EXTERNAL_LEGAL_REVIEW_BRIEF_2026-08-07.md` | Codex; não constitui parecer jurídico |
