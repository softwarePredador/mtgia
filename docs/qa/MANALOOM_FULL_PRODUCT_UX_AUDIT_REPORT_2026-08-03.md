# Relatório — auditoria integral de produto e UX do ManaLoom

**Rodada:** 2026-08-03
**Estado:** `DIAGNOSTIC_COMPLETE · UX_PACKS_01_08_COMPLETE_LOCAL · POLISH_P2_COMPLETE_LOCAL · CURRENT_RUNTIME_22_242 · GLOBAL_REANCHOR_INCOMPLETE · RELEASE_HUMAN_GATES_PENDING`
**Decisão:** `GO` para encerrar o polish P2 local; `NO_GO` para aprovação visual global, release, migration ou deploy
**Pacotes propostos:** [MANALOOM_UX_IMPLEMENTATION_PACKETS_2026-08-03.md](MANALOOM_UX_IMPLEMENTATION_PACKETS_2026-08-03.md)
**Tracker:** [MANALOOM_FULL_PRODUCT_UX_AUDIT_TRACKER_2026-08-03.md](MANALOOM_FULL_PRODUCT_UX_AUDIT_TRACKER_2026-08-03.md)

> **Continuação em 2026-08-05:** o diagnóstico abaixo permanece como baseline.
> Os pacotes autorizados 01–04 agora fecham identidade/printing, ingestão em
> lote sem migration, workshop verificável e partida → replay → pós-jogo →
> Optimize. A prova corrente reúne 14 manifests e 294 capturas no digest
> `93009fc2…`: 214 da matriz P0, 5 Battle Live, 21 Binder Import, 24 Deck
> Workshop e 30 Battle Learning. Cada PNG foi aberto e reconciliado por hash;
> os três níveis obrigatórios passaram sem finding visual bloqueante. Os
> limites e follow-ups estão na
> [reancoragem global de UI](MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md).

> **Continuação em 2026-08-06:** o `UX-PACK-05` resolveu localmente a jornada
> faltante → match → Marketplace → proposta, separou Marketplace de Cotações,
> tornou deep links recuperáveis, adicionou comentário contextual e
> contraproposta atômica para troca pura. A prova focal abriu `48/48` PNGs Web
> release em três larguras no digest `70322d07…`. A primeira captura mobile
> expôs campos espremidos; a composição passou a usar a largura local do card,
> foi recapturada e ganhou teste de regressão. O aggregate global anterior
> permanece histórico e fail-closed até reancoragem integral. Detalhes:
> [UX-PACK-05](MANALOOM_UX_PACK_05_IMPLEMENTATION_2026-08-06.md).

> **Continuação do Pack 07 em 2026-08-06:** Profile, perfil público, primeiro
> deck, quota e estados transversais foram recompostos como workbench de
> jogador. Save ganhou dirty/saving/success/error inline; quota passou a usar
> somente o modelo de ações usadas; primeiro uso, zero resultados, erro,
> offline e indisponível deixaram de compartilhar o mesmo painel genérico.
> `30/30` PNGs Web release foram abertos em três larguras no digest
> `a408c2a3…`, sem corte ou sobreposição bloqueante. O aggregate anterior não
> foi promovido: a política exigia 23 manifests/387 capturas naquele ponto. Detalhes:
> [UX-PACK-07](MANALOOM_UX_PACK_07_IMPLEMENTATION_2026-08-06.md).

> **Fechamento do Pack 08 em 2026-08-06:** 22 estados críticos por perfil
> passaram a ligar source, anchor, teste, estágio e política de mutation.
> Profile/security, deck delete, commander, Fichário, Trade, sessão expirada e
> permissão negada produziram `66/66` PNGs Web release no digest `60bbef19…`;
> todos foram abertos depois de corrigir um picker excessivamente alto e um
> snackbar duplicado. A política agora exige 26 manifests/453 capturas. O
> aggregate anterior permanece fail-closed. Detalhes:
> [UX-PACK-08](MANALOOM_UX_PACK_08_IMPLEMENTATION_2026-08-06.md).

> **Reancoragem global final em 2026-08-06:** P0, Battle Live e os Packs
> 02–08 foram recapturados no digest `f45f96e3…`. Os `26/26` manifests e
> `453/453` PNGs foram reconciliados por bytes, dimensão e SHA-256; todas as
> imagens foram abertas individualmente. Os três níveis obrigatórios passaram
> com zero finding bloqueante. O resultado canônico está na
> [reancoragem global de UI](MANALOOM_GLOBAL_UI_REANCHOR_2026-08-05.md).

> **Polish responsivo P2 em 2026-08-07:** continuidade horizontal, nomes
> longos e fixtures foram fechados; a composição de Legal/Privacy foi aceita
> e a copy continua sob revisão jurídica externa. Battle Live e UX-PACKs 02–08
> têm `22/22` manifests e `242/242` PNGs `PASS_RUNTIME` no digest
> `ebacfe42…`; 21 checkpoints diretamente afetados foram abertos. A aprovação
> global não foi transportada: `latest.json` e P0 `4/214` continuam no digest
> anterior porque a fixture PostgreSQL loopback não foi autorizada. Detalhes:
> [polish P2](MANALOOM_UX_POLISH_RESPONSIVE_P2_IMPLEMENTATION_2026-08-07.md).

## 1. Resultado executivo do diagnóstico de origem

O ManaLoom já possui uma base funcional ampla, identidade própria reconhecível e alguns momentos visuais fortes. Autenticação, Home, detalhe de carta, card de deck e Life Counter demonstram que o produto pode parecer uma ferramenta de Magic premium. O problema principal não é falta geral de funcionalidades nem falta de tema.

O problema é que o ciclo que diferencia o produto ainda se rompe entre superfícies:

```text
descobrir → colecionar → montar → entender faltantes → testar → jogar
    → registrar o que ocorreu → transformar isso em uma alteração verificável
```

Hoje, muitas etapas existem isoladamente, mas o contexto não chega à etapa seguinte. Em paralelo, diversas superfícies autenticadas repetem o mesmo padrão de painel escuro, filtros, cards retangulares e estado vazio centralizado. Isso faz uma base tecnicamente rica parecer um dashboard administrativo temático.

### Cinco conclusões centrais

1. **A identidade da carta não é consistente entre superfícies.** O mesmo deck mostra carta real na lista, mas arte genérica no detalhe, na lista interna, no sample hand, em sets e em comunidade. Busca de coleção pode apresentar duas impressões visualmente idênticas.
2. **O aprendizado da partida não fecha o ciclo.** Pós-jogo registra cartas como texto livre e abre Optimize somente com a intenção `post_game`; notas, problemas e cartas citadas não condicionam a recomendação.
3. **Coleção e trades são funcionais, porém pouco acionáveis.** Não há importação de coleção em lote; scanner está deferido e o fluxo existente é de uma carta por vez; faltante → oferta → trade não preserva identidade da carta de ponta a ponta.
4. **Empty states explicam mais do que conduzem.** Ofertas, Trocas, Usuários, Mensagens, Notificações e Cotações informam a ausência de dados, mas quase nunca oferecem uma próxima ação contextual.
5. **A prova atual aprova o conjunto P0 declarado, não o produto inteiro.** Há 219 capturas correntes, mas quase nenhum overlay aberto e pouca prova visual de loading, saving, retry, offline, stale, session-expired e permission-denied.

Nenhum `P0` foi confirmado nesta rodada. Foram confirmadas quebras `P1` de continuidade, confiança e reconhecimento, além de dívida `P2` de desejabilidade, densidade e uso de espaço. As cinco conclusões acima são o baseline que orientou os oito pacotes; não representam o estado final depois das implementações.

### Estado corrente após os UX-PACKs 01–08

Os pacotes fecharam localmente identidade/printing compartilhada, Binder em
lote sem migration, Oficina verificável, partida → aprendizado → Optimize,
faltante → match → proposta, onboarding por intenção, Profile como workbench e
os overlays/estados críticos. A largura mobile reclamada pelo usuário foi
corrigida e não reapareceu na matriz global.

A prova final mostrou uma experiência visual coerente e reconhecível como
Magic nas jornadas principais, com carta, deck, comandante, partida e pessoa
usados como contexto em vez de decoração. O backlog visual restante é
não-bloqueante e está ordenado assim:

1. `P1`: evitar `Visão Ge` nas abas mobile do detalhe de deck;
2. `P1`: recompor densidade de vazios/resultados únicos em desktop e wide;
3. `P2`: tornar a rolagem horizontal de carrosséis mais evidente;
4. `P2`: padronizar nomes longos no Profile;
5. `P2`: melhorar realismo/contexto das fixtures visuais;
6. `P2/governança`: refinar Legal/Privacy e obter revisão jurídica externa.

## 2. Evidência e limites

### Base técnica

| Item | Resultado |
|---|---|
| SHA no início da inspeção | `a16e189170fecd31bb015c538dd6f2860777c602` |
| SHA ao consolidar o relatório | `95afa75b860fabb9e8f13cb1c309b98c260ba2aa` |
| Drift durante a rodada | dois commits externos à auditoria; digest de UI permaneceu estável |
| Digest de UI no diagnóstico | `3b20f72472d724d6c0a68c868c4399ea88d3527f2a9aedf2514d47bd4ec16207` |
| Digest de UI no fechamento global | `f45f96e34ca6b00c34952b25631c6ff3157e85e39afc06e1f8394e1484f0e90e` |
| Digest do manifesto ao final | `af4ce1b4006440cf90dc9c902b7d560789f71e0fee4a1b6f0be6b6e2a5432d76` |
| Análise semântica | `complete`: 662 arquivos resolvidos, 0 não resolvidos, 39.561 call edges, 63.006 call sites e 15.132 referências de tipo |
| Lineage | 2.617 inputs; `sha256(path + file_sha256)` |

O checkout já continha alterações alheias. A auditoria não limpou, reverteu, commitou nem publicou nada.

### Prova exercitada

- `./scripts/manaloom_ui_live_evidence_gate.sh --check`: `PASS`;
- `./scripts/quality_gate.sh ui-proof`: `PASS`;
- `./scripts/quality_gate.sh ui-audit`: `PASS`;
- `26/26` manifests `PASS_RUNTIME` no mesmo digest e `453/453` capturas
  abertas individualmente: 214 P0, 5 Battle Live, 21 Binder Import, 24 Deck
  Workshop, 30 Battle Learning, 48 Social/Trade, 15 Onboarding Intent, 30
  Visual System Workspace e 66 Critical Overlays and States;
- bytes, dimensões e SHA-256 recalculados para cada PNG: `453 válidos; 0
  inválidos`;
- build Web release real em Chrome 150 e Samsung SM-A135M físico, Android 14,
  exercitados no digest final;
- o [README de progresso visual do Battle Live](ui-live/reference/2026-08-03-battle-live-progress/README.md) fornecido pelo usuário foi usado como referência de capturas e estados, sem herdar aprovação para outro digest ou superfície;
- o fixture terminou com banco removido, zero listeners Web/API e credenciais removidas.

### O que a prova não fecha

- TalkBack humano, teclado Web real e smoke de hardware/release continuam pendentes e não receberam crédito;
- o Pack 08 cobre os overlays/estados de maior risco, mas o inventário das 263
  ocorrências não equivale a uma prova visual individual de cada ocorrência;
- scanner físico permanece condicionado à feature flag e a uma rodada própria;
- manifestos de Battle Coach Android, teclado Web, core-product Android, card navigation/fallback e optimization reader foram abertos apenas como referência histórica e permanecem `stale_not_claimed`.

### Marco histórico de evidência em 2026-08-05

No digest de UI
`4f0194c39d4e200787b0b6aeecd9390d9669d932ca690fa37e44b5f2420342f8`,
foram recapturadas e abertas individualmente 54 telas Web mobile, 53 desktop,
53 wide e 54 no Samsung SM-A135M físico, Android 14. Battle Live acrescentou
cinco estados correntes. A revisão das 219 imagens não achou overlap, corte
estrutural ou CTA principal inacessível.

Ela confirmou como oportunidades, e não como regressões bloqueantes:

- vazios sociais e transacionais ainda explicam mais do que conduzem;
- perfis continuam com identidade visual mínima;
- Generate/Import, onboarding, Battle/replay e pós-jogo permanecem textuais;
- Battle Live não oferece reconhecimento visual da carta citada na timeline;
- coleção é densa e trunca métricas; o pós-jogo wide quebra `Reconstruir`;
- carrosséis de métricas, filtros e abas cortam o próximo item no Android com
  affordance horizontal fraca;
- o fixture repete miniaturas, limitando a avaliação de diversidade real do catálogo.

O Samsung SM-A135M físico concluiu `54/54` checkpoints, incluindo o Life
Counter nativo em landscape. O reparo `UX-019` substituiu a entrada frágil do
harness por preparação controlada pelo `TextEditingController`, espera do
estado detectado e assertivas que exigem o texto retido, o contador e sua
presença no viewport. O teste de política protege essas condições. Nos quatro
perfis P0, `deck_import_detected.png` passou a mostrar `1 Sol Ring`,
o contador detectado e `Criar Deck`. A rodada final corrigiu a flexão para
`1 carta detectada`.

Os quatro manifests P0 e o manifest de Battle Live foram indexados no mesmo
digest e compostos no aggregate daquele marco com seus
SHA-256 exatos. `manaloom_ui_live_evidence_gate.sh --check`,
`quality_gate.sh ui-proof` e `quality_gate.sh ui-audit` passaram; o aggregate
registrava `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED` para 219
capturas. O finding `UX-019` está resolvido. A fixture terminou com banco
remanescente 0, listeners Web/API 0 e credenciais removidas. TalkBack humano,
teclado Web real e smoke de hardware/release continuam verificações separadas.

## 3. O que já funciona bem

| Área | Evidência | Leitura |
|---|---|---|
| Auth | login, registro, recuperação, reset e verificação usam shell visual próprio | distintivo, coerente e apropriado sem depender de card art |
| Home | hero ManaLoom, próxima ação e deck recente | orientação rápida e identidade visual forte |
| Detalhe de carta | arte grande, regras e metadados em hierarquia clara | melhor exemplo atual de imagem fazendo trabalho de reconhecimento |
| Lista de decks | card de deck com comandante, formato, contagem e validação | objeto real é legível e desejável |
| Life Counter | números dominantes, cor por jogador e controles imediatos | prioridade de mesa correta; card art é opcional, não requisito |
| Optimize | configuração explícita, coleção/orçamento, preview antes/depois e aplicação seletiva existem no código | boa direção de controle humano; falta continuidade e prova corrente mais ampla |
| Análise | etapas e fontes são progressivamente reveladas inline | melhor do que modal informativo; não oculta indisponibilidade |
| Comercial beta | planos, upgrade e checkout não simulam cobrança | transparente e seguro |
| Legal | separa termos, privacidade, IA, IP e trades | conteúdo visualmente sóbrio é apropriado |

## 4. Pesquisa de usuários e referências

### Observação oficial

- ManaBox usa sessão de scanner, revisão posterior, correção de impressão/foil/idioma/condição, edição em massa e resumo de erros de importação. [Scanner](https://www.manabox.app/guides/scanner/getting-started/), [coleção e decks](https://www.manabox.app/guides/decks/collection-decks/), [importação/exportação](https://www.manabox.app/guides/collection/import-export/).
- Archidekt trata o deckbuilder como superfície visual, oferece modos de imagem/texto e removeu um overlay intermediário do deck vazio para ensinar ações na própria tela. [Static Card View](https://archidekt.com/news/20605672), [Mobile UI overhaul](https://archidekt.com/news/22633051), [Deck Help](https://archidekt.com/news/24799503).
- Scryfall diferencia identidade Oracle de impressão física, expõe `image_status`, legalidade, idioma, set, collector number e rulings com fonte/data. [API](https://scryfall.com/docs/api), [imagens](https://scryfall.com/docs/api/images), [cartas](https://scryfall.com/docs/api/cards), [rulings](https://scryfall.com/docs/api/rulings).
- EDHREC declara fonte, coleta, amostra e limitações, e reconhece viés de popularidade e feedback loop. [Guia](https://edhrec.com/guides/how-to-use-edhrec), [metodologia Lift](https://edhrec.com/articles/from-synergy-to-lift-the-math-behind-edhrecs-new-era).
- Magic Companion prioriza estado e próxima ação em pairing, vida e resultado; card art pertence à descoberta, não a toda tela transacional. [Produto](https://magic.wizards.com/en/products/companion-app), [Player Profiles](https://magic.wizards.com/en/news/announcements/companion-app-update-magic-player-profiles).

### Sinais qualitativos de usuários

Relatos recentes convergem em quatro dores: alternar ferramentas para tarefas diferentes; localizar cada cópia física; perder printing/tags em importação; e redesigns móveis que escondem ações frequentes. Há preferência por dois modos equivalentes — imagem para reconhecimento e lista para densidade. [Escolha de deckbuilder](https://www.reddit.com/r/EDH/comments/1k49c28/which_deck_builder_app_do_you_use_and_why/), [dores de coleção/deck](https://www.reddit.com/r/mtg/comments/1ud8jyh/what_do_current_mtg_collectiondeckbuilding_apps/), [migração de coleção](https://www.reddit.com/r/mtgfinance/comments/1rqfuk5/looking_to_transfer_my_collection_from_mtgstocks/).

Sobre IA, os relatos incluem cartas inexistentes, tipos incorretos, listas ilegais e explicações convincentes porém erradas. A aceitação aumenta quando o jogador pode verificar fonte, comparar mudanças e manter a decisão final. [Discussão sobre regras/sugestões](https://www.reddit.com/r/EDH/comments/1q0epg2/do_not_use_ai_to_make_deck_suggestions_or_clarify/), [IA assistida e controle humano](https://www.reddit.com/r/mtg/comments/1tjmyhb/ai_assisted_deck_building_is_lame/).

Esses relatos demonstram existência da dor, não prevalência populacional.

### Inferência para o ManaLoom

Card art só deve receber crédito quando ajuda a reconhecer, comparar, confirmar impressão, simular posição, criar identidade escolhida ou explicar recomendação. Segurança, legal, pairing e estados técnicos não precisam de imagem decorativa.

A IA deve atuar como **copiloto verificável**: entrada e restrições visíveis, validação determinística, motivo por mudança, fonte/coorte/freshness, diff, aprovação seletiva, snapshot e rollback.

## 5. Disposição das 41 rotas

Legenda: `FORTE`, `GAP_P1`, `GAP_P2`, `DEFERRED`, `REDIRECT`.

| # | Rota | Disposição | Síntese |
|---:|---|---|---|
| 1 | `/` | `FORTE` | splash original e coerente |
| 2 | `/login` | `FORTE` | marca, CTA e recuperação claros |
| 3 | `/register` | `FORTE` | consentimento visível; densidade mobile exige monitoramento |
| 4 | `/forgot-password` | `FORTE` | job único e recuperação clara |
| 5 | `/reset-password` | `FORTE` | link inválido tem recuperação explícita |
| 6 | `/legal` | `GAP_P2` | visual adequado; conteúdo ainda é beta e revisão jurídica externa está pendente |
| 7 | `/verify-email` | `FORTE` | estado e próxima ação claros |
| 8 | `/life-counter` | `GAP_P2` | mesa forte; entrada por Home perde deck e saída pós-jogo |
| 9 | `/home` | `FORTE` | hero e próxima ação claros; deck recente usa arte inconsistente |
| 10 | `/onboarding/core-flow` | `GAP_P1` | formulário/painéis homogêneos; gerar/importar não conclui onboarding |
| 11 | `/decks` | `FORTE` | card visual útil; wide subutilizado |
| 12 | `/decks/generate` | `GAP_P1` | comandante é texto livre e preview não é visual/verificável |
| 13 | `/decks/import` | `GAP_P1` | conta linhas antes de criar, mas não mostra preflight visual por carta/impressão |
| 14 | `/decks/:id` | `GAP_P1` | muita capacidade, porém arte e disponibilidade são inconsistentes; undo não é reencontrável |
| 15 | `/decks/:id/search` | `GAP_P1` | owned/free/allocated/missing existe; filtros não são endereçáveis e printing é pouco controlável |
| 16 | `/decks/:id/scan` | `DEFERRED` | redireciona para busca manual |
| 17 | `/decks/:id/post-game` | `GAP_P1` | cartas são nomes livres; aprendizado não chega ao Optimize |
| 18 | `/decks/:id/battle-replays` | `GAP_P2` | modos e CTA claros; vazio é grande e pouco contextual |
| 19 | `/decks/:id/battle-coach/:sessionId` | `DEFERRED` | evidência visual existente está stale |
| 20 | `/decks/:id/battle-coach` | `DEFERRED` | evidência visual existente está stale |
| 21 | `/decks/:id/battle-live/:jobId` | `GAP_P2` | estados são honestos; experiência parece telemetria administrativa, sem mesa/cartas |
| 22 | `/plans` | `GAP_P2` | transparente; barra mede usado enquanto copy comunica restante |
| 23 | `/cards/:cardId` | `FORTE` | imagem, regra e metadados bem hierarquizados; falta ligação visível a rulings oficiais |
| 24 | `/upgrade` | `FORTE` | bloqueio comercial honesto |
| 25 | `/checkout` | `FORTE` | captura link antigo sem coletar pagamento |
| 26 | `/collection` | `GAP_P1` | busca/editor bons, mas sem lote; duas impressões podem parecer idênticas |
| 27 | `/collection/latest-set` | `GAP_P2` | cards têm thumbnails genéricas repetidas e `5/6` sem explicação acionável |
| 28 | `/collection/sets` | `GAP_P2` | catálogo coerente; pouco uso de espaço e arte |
| 29 | `/collection/sets/:code` | `GAP_P1` | catálogo de cartas sem reconhecimento visual real |
| 30 | `/market` | `REDIRECT` | vai para Cotações, enquanto Marketplace real vive em `/collection?tab=1` |
| 31 | `/community` | `PARTIAL` | Cotações têm destino próprio; navegação social e estados vazios são acionáveis; descoberta ampla continua limitada |
| 32 | `/community/search-users` | `PARTIAL` | query sobrevive a reload e vazio permite limpar; sugestões por afinidade continuam fora do escopo |
| 33 | `/community/user/:userId` | `GAP_P2` | perfil administrativo, pouca identidade do jogador |
| 34 | `/community/decks/:deckId` | `FORTE` | feedback pode ancorar deck/categoria/carta e o match abre oferta compatível com identidade exata |
| 35 | `/profile` | `GAP_P2` | settings genérico; Save habilitado sem dirty state; diálogos sem prova atual |
| 36 | `/messages` | `FORTE` | vazio explica origem das conversas e abre busca de jogadores diretamente |
| 37 | `/messages/:conversationId` | `GAP_P2` | erro recuperável; contexto da carta/deck não é preservado |
| 38 | `/notifications` | `GAP_P2` | vazio informativo sem ação ou preferências contextuais |
| 39 | `/trades` | `FORTE` | inbox separa recebidas/enviadas/finalizadas e vazio abre matches |
| 40 | `/trades/create/:receiverId` | `FORTE` | receiver, item, tipo, origem, deck e contraproposta sobrevivem a reload/share |
| 41 | `/trades/:tradeId` | `FORTE` | proposta, contraproposta, recusa, erro e conclusão têm ações, histórico e prova visual corrente |

Rotas acrescentadas pelos pacotes autorizados não alteram o ledger histórico
acima: `/collection/matches` é o destino de faltantes, `/marketplace` converge
para Ofertas e `/quotes` converge para Cotações. O inventário executável
corrente reconcilia `45` ocorrências de `GoRoute`.

## 6. As 12 jornadas

| # | Jornada | Estado | Ruptura principal |
|---:|---|---|---|
| 1 | Descobrir comandante/tema | `PARTIAL` | descoberta começa em prompt/texto; `from=onboarding` não fecha o onboarding |
| 2 | Pesquisar/compreender carta | `PARTIAL` | busca global ausente/oculta; ruling oficial não está ligado à explicação da IA |
| 3 | Importar/escanear coleção | `MISSING/PARTIAL` | não há importação de coleção; scanner deferido; fluxo é uma carta por vez |
| 4 | Corrigir impressão/localização | `PARTIAL` | item existente não troca impressão; localização é nota livre |
| 5 | Criar/gerar/importar deck | `EXISTS` | drafts locais ajudam, mas não são cross-device e a revisão visual é insuficiente |
| 6 | Montar com possuídas/livres | `PARTIAL` | modelo backend é forte; detalhe do deck não mostra disponibilidade por linha |
| 7 | Interpretar diagnóstico | `EXISTS` | fontes/taxonomias são transparentes, porém muitas aparecem indisponíveis ou sem definição visível |
| 8 | Comparar/aplicar/testar/desfazer | `PARTIAL` | diff e rollback existem; histórico/undo só aparece em snackbar transitório |
| 9 | Localizar/negociar faltantes | `COMPLETE_LOCAL` | cópia pública exata atravessa match, oferta e proposta; backend revalida disponibilidade |
| 10 | Compartilhar/receber feedback | `PARTIAL` | comentário ancora deck/categoria/carta; share estruturado e diff continuam como evolução futura |
| 11 | Iniciar/retomar/encerrar partida | `PARTIAL` | deck abre sessão coerente; Home não passa deck nem consome resultado pós-jogo |
| 12 | Transformar partida em ajuste | `PARTIAL` | Optimize recebe a intenção, não a evidência registrada |

## 7. Findings priorizados

| ID | Sev. | Finding confirmado | Consequência |
|---|---|---|---|
| `UX-001` | P1 | pós-jogo → Optimize perde notas, issues e cartas | recomendação não aprende com a partida que motivou a ação |
| `UX-002` | P1 | coleção não possui importação em lote e scanner está deferido | usuário com caixa grande precisa cadastrar uma carta por vez ou usar outro produto |
| `UX-003` | P1 | impressão não é distinguível/corrigível de forma consistente | risco de posse, preço e trade representarem a cópia errada |
| `UX-004` | P1 | faltante → oferta → trade perde identidade e vira informação | a jornada de resolver faltas não fecha dentro do ManaLoom |
| `UX-005` | P1 | card art varia entre real, arte genérica e fallback no mesmo contexto | reconhecimento e confiança quebram entre lista, detalhe, playtest, set e comunidade |
| `UX-006` | P1 | importação de deck não oferece preflight visual por linha/impressão | ambiguidades aparecem tarde e a revisão começa depois da criação |
| `UX-007` | P1 | onboarding não encerra ao gerar/importar e não oferece descoberta visual | primeiro uso pode permanecer pendente e parecer formulário genérico |
| `UX-008` | P1 | Home → Life Counter perde deck e não retorna ao pós-jogo | a partida iniciada pela ação principal não alimenta retenção/aprendizado |
| `UX-009` | P1 | recomendação/`0%`/fontes indisponíveis não explicam definição ou amostra no ponto de decisão | métricas parecem autoridade sem base compreensível |
| `UX-010` | P1 | undo de otimização existe, mas sua entrada é transitória | recuperação durável do backend não é reencontrável na UI |
| `UX-011` | P1 | prova corrente quase não cobre overlays e estados de falha por domínio | release pode aprovar aparência sem provar recuperação crítica |
| `UX-012` | P1 | documentação de prova diverge em contagens, dispositivo e manifestos correntes | governança pode atribuir crédito a evidência antiga |
| `UX-013` | P2 | vazios repetem painel central sem CTA contextual | superfícies parecem becos sem saída e reduzem descoberta |
| `UX-014` | P2 | wide mantém colunas estreitas e grandes áreas vazias | desktop premium parece mobile esticado, não workspace de deckbuilding |
| `UX-015` | P2 | Profile e perfis públicos mostram inicial e settings, sem identidade Magic | pessoa é tratada como conta, não como jogador |
| `UX-016` | P2 | barra de IA visualiza usado enquanto texto comunica restante | leitura rápida pode sugerir quota zerada ou quase esgotada |
| `UX-017` | P2 | Battle Live usa cards/chips de telemetria sem representação espacial | acompanhar partida parece monitorar job, não assistir Magic |
| `UX-018` | P2 | Save do perfil é dominante e habilitado sem alteração aparente | estado de edição e sucesso não são claros |

### Estado corrente após o UX-PACK-08 e a reancoragem

- `UX-004`: `RESOLVED_LOCAL · FOCAL_WEB_VISUAL_PASS`;
- `UX-009`: contexto de match/oferta e freshness resolvidos no escopo social;
  análise não social permanece no pacote correspondente;
- `UX-013`: `RESOLVED_FOR_AUTHORIZED_SURFACES`; Social/Trade, onboarding,
  Home, Decks e os estados compartilhados usam contexto e ação real;
- `UX-015`: `RESOLVED_LOCAL`; perfil próprio e público distinguem identidade
  do jogador, privacidade, decks, conta e segurança;
- `UX-007`: `RESOLVED_LOCAL · FOCAL_WEB_VISUAL_PASS`; intenção, conclusão,
  skip, retomada e Home contextual foram comprovados em 15 capturas Web
  release;
- `UX-008`: o residual de onboarding foi fechado no Pack 06; a jornada
  Home/mesa/pós-jogo continua preservando o contrato do Pack 04;
- `UX-014`, `UX-015`, `UX-016` e `UX-018`: `RESOLVED_LOCAL` no Pack 07, com
  Profile/perfil público recompostos, quota por ações usadas e Save stateful;
- `UX-011` e `UX-012`: `RESOLVED_CURRENT_DIGEST`; estados críticos e
  governança de prova estão no aggregate corrente;
- `UX-019`: `RESOLVED_CURRENT_DIGEST`, com entrada detectada, flexão singular
  correta e CTA presentes nos quatro perfis P0;
- o aggregate global contém `26/26` manifests e `453/453` capturas no digest
  `f45f96e3…`, todas abertas e reconciliadas.

## 8. Auditoria de imagens

Esta tabela registra o diagnóstico original de 2026-08-03. As mitigações
autorizadas de 2026-08-05 não apagam a evidência de origem; o estado corrente
por superfície está na matriz do tracker e no relatório do `UX-PACK-01`.

| Superfície | Resultado | Decisão futura |
|---|---|---|
| auth/legal/comercial | `IMAGE_NOT_APPLICABLE` | manter foco em confiança e copy |
| Home hero | `IMAGE_PRESENT_USEFUL` | preservar; trocar thumbnails genéricas por comandante/deck real |
| card detail | `IMAGE_PRESENT_USEFUL` | preservar; mostrar impressão e status da imagem |
| deck list | `IMAGE_PRESENT_USEFUL` | preservar nos modos visuais; oferecer compacto |
| deck detail/lista/sample hand | `IMAGE_REQUIRED_MISSING` | unificar identidade e fallback por impressão |
| generate/import | `IMAGE_REQUIRED_MISSING` | commander picker e preflight visual antes de criar |
| collection editor | `IMAGE_PRESENT_USEFUL` | preservar; permitir comparar impressões lado a lado |
| collection search | `IMAGE_REQUIRED_MISSING` | distinguir printing, collector number, finish e idioma antes de salvar |
| sets/set detail | `IMAGE_REQUIRED_MISSING` | grade visual + modo lista; explicar cartas faltantes |
| optimize | `COMPACT_MODE_NEEDED` + imagem sob demanda | pares add/cut com thumbnail, reader e diff; não transformar tudo em galeria |
| Battle Coach | `IMAGE_PRESENT_USEFUL` em evidência stale | recapturar no digest corrente antes de crédito |
| Battle Live/replay | `IMAGE_REQUIRED_MISSING` quando o contrato fornecer identidade | mesa/zonas/cartas; manter modo textual acessível |
| post-game | `IMAGE_REQUIRED_MISSING` | selecionar cartas reais do deck, não nomes livres |
| comunidade/trades | `IMAGE_PRESENT_USEFUL · UX_PACK_05_VISUAL_PASS` | preservar arte exata, printing e pessoa; fallback sem identidade permanece honesto |
| Life Counter | `IMAGE_NOT_APPLICABLE` por padrão | arte de comandante escolhida pode ser opt-in sem competir com vida |

## 9. Modais, sheets e transientes

O problema não é quantidade isolada. A decisão por classe é:

| Classe | Exemplos | Decisão |
|---|---|---|
| `SAFETY_CONFIRMATION` | excluir conta/deck, revogar sessões, conceder partida | manter modal; provar foco, cancelamento e consequência |
| `BOUNDED_PICKER` | condição, idioma, bracket curto, escolha de lista | sheet/modal é aceitável |
| `QUICK_EDIT` | item único do fichário, edição curta de carta | manter se draft e erro persistirem |
| `FLOW_CANDIDATE` | criar deck, import review, optimize longo, scanner/lote, trade multietapa | promover a rota/painel persistente quando houver retomada, diff ou correção |
| `INLINE_EDUCATION` | etapas/fonte/confiança da análise | manter inline/accordion; a implementação atual é boa referência |
| `DEAD_END_INFO` | vazios sem CTA, indisponibilidade sem alternativa | transformar em estado acionável |
| `HIDDEN_PRIMARY_ACTION` | undo apenas em snackbar, mercado em rota diferente | tornar persistente e contextual |
| `TRANSIENT_MISUSE` | erro ou decisão que exige correção/rollback | mover para estado inline ou histórico |

Sem recaptura `action → open → final`, não há aprovação visual dos 49 dialogs, 23 sheets e 9 menus. O pacote de evidência deve priorizar os fluxos destrutivos, optimize, collection editor, create deck, commander picker, trade item picker e perfil.

## 10. Scorecard do diagnóstico de origem

Escala `0–4`; as notas preservam a evidência que originou os pacotes, não o
estado final nem qualidade absoluta. O fechamento pós-Pack 08 é expresso pelos
três níveis de evidência e pelo backlog residual, sem fabricar uma nova nota
sem pesquisa quantitativa com usuários.

| Dimensão | Nota | Síntese |
|---|---:|---|
| Clareza | 3 | títulos e CTAs geralmente claros; métricas e vazios têm exceções |
| Continuidade | 1 | principais rupturas estão entre módulos, não dentro de uma tela |
| Valor | 3 | funcionalidades centrais existem e resolvem jobs reais |
| Ação | 2 | várias telas terminam em informação ou instrução sem CTA |
| Identidade visual | 3 | marca forte em auth/Home; superfícies internas ficam genéricas |
| Imagem significativa | 2 | excelente no detalhe/lista; inconsistente no resto do ciclo |
| Hierarquia/densidade | 2 | mobile é sólido; wide e telas longas acumulam painéis |
| Confiança | 2 | boa transparência beta; IA, métricas e printing ainda frágeis |
| Recuperação | 2 | erros básicos têm retry; undo, offline e conflito não têm prova ampla |
| Inclusão | 2 | semântica/testes passam; TalkBack humano e teclado atual pendentes |
| Responsividade | 3 | não houve overflow bloqueante; recomposição wide é insuficiente |
| Desejabilidade | 2 | momentos fortes coexistem com muitos estados administrativos repetidos |

## 11. Ordem recomendada

1. **P1 — corrigir a navegação de abas mobile do detalhe de deck**, impedindo
   `Visão Ge` e deixando a continuidade horizontal inequívoca.
2. **P1 — recompor densidade desktop/wide** em vazios, resultados únicos e
   telas administrativas, usando rail, contexto e ação sem preencher com
   decoração irrelevante.
3. **P2 — melhorar affordance dos carrosséis mobile** de cartas, printings e
   evidências.
4. **P2 — normalizar nomes longos no Profile** e revisar composição de
   fixtures/evidências isoladas.
5. **P2/governança — refinar Legal/Privacy** e obter revisão jurídica externa.
6. **Release separado — executar TalkBack humano, teclado Web real e smoke no
   Samsung**, sem atribuir esses créditos à revisão visual automatizada.

A descrição executável, wireflows e critérios de aceite estão nos [pacotes de implementação](MANALOOM_UX_IMPLEMENTATION_PACKETS_2026-08-03.md).

## 12. Decisão e próximo sinal

A fase diagnóstica não implementou UI, regra, rota, banco, runtime ou deploy.
Depois dela, o usuário autorizou progressivamente os `UX-PACK-01` a
`UX-PACK-08`, agora concluídos no escopo local documentado. O ADR 0008 fecha a
fronteira decklist/cópia física; o ADR 0009 fecha navegação, deep links,
privacidade, contexto e contraproposta social/trade. As provas focais e a
reancoragem global passaram no mesmo digest com `26/453`.

O próximo sinal recomendado é `IMPLEMENTAR POLISH RESPONSIVO P1`, limitado a
abas mobile do detalhe de deck e densidade desktop/wide. TalkBack humano,
teclado Web real e smoke físico devem ser executados como gates separados
antes de qualquer decisão de release. Nenhuma aprovação desta rodada autoriza
release, migration, deploy, commit ou push; qualquer patch app-facing muda o
digest e exige uma nova reancoragem.

## 13. Atualização pós-auditoria — polish responsivo P1

Em 2026-08-06 o usuário autorizou a continuidade e as duas prioridades P1
foram implementadas localmente. O detalhe de deck preserva `Visão Geral` por
inteiro em 390×844, com rolagem de abas somente no breakpoint compacto.
Estados com pouco conteúdo passaram a usar rail + workspace em desktop/wide e
o match único de Trade ganhou composição mestre–detalhe, mantendo largura útil
completa no mobile.

Analyzer focal e `37/37` testes focais passaram. A suíte Flutter completa
fechou `1525 PASS + 1 skip governado` e `quality_gate.sh full` passou backend,
Flutter, site público, dependency audit, smoke e harnesses locais com o Node 26
já instalado. Foram abertas 21 capturas finais nos três breakpoints — estados
compartilhados, match único, perfis e workshop — sem overflow, campo estreito
ou perda de CTA. Battle Live e UX-PACKs 02–08 somam `239/239` capturas
`PASS_RUNTIME` no novo digest `df8c3371…`.

Os gates também corrigiram afirmações de offline em falhas genéricas, migraram
as novas larguras para tokens canônicos e deram anchors estáveis aos dois
retries cuja classe visual havia mudado. `ui-audit` aprovou `56/56` testes e
então manteve o fail-closed do aggregate antigo.

A aprovação global permanece fail-closed: os quatro perfis P0, com 214
capturas, continuam no digest anterior porque a recaptura autenticada exige
PostgreSQL loopback descartável e a atividade atual proíbe escrita em
PostgreSQL. Nenhum `PASS_VISUAL_REVIEWED` antigo foi transportado. O registro
completo está em
[MANALOOM_UX_POLISH_RESPONSIVE_P1_IMPLEMENTATION_2026-08-06.md](MANALOOM_UX_POLISH_RESPONSIVE_P1_IMPLEMENTATION_2026-08-06.md).

Com o P1 implementado e o gate completo local verde, a próxima frente visual é
P2: affordance dos carrosséis
mobile, nomes longos no Profile, qualidade das fixtures e Legal/Privacy. Gates
humanos/de hardware continuam separados.

## 14. Atualização pós-auditoria — polish responsivo P2

Em 2026-08-07 o usuário autorizou a continuidade e o backlog visual P2 foi
fechado localmente. Cartas, impressões e evidências horizontais agora usam um
rail compartilhado com instrução, controle de 48 px, semântica e movimento
reduzido, sempre fora da card art. Sample Hand comunica posição e gesto.

Profile próprio e público usam o mesmo contrato de nome: até duas linhas e
elipse visual, com identidade integral em semântica/tooltip. As fixtures de
Deck Workshop e Battle Learning passaram a provar comandante + CTA, mão
inicial, imagens distintas e estados reconhecíveis, sem alegar que arte de
fixture comprova printing oficial.

Legal/Privacy foi separado em duas decisões: sua composição de UI — largura de
leitura, versões, navegação e seções sóbrias — está concluída; a validade da
copy e dos contratos permanece `EXTERNAL_LEGAL_REVIEW_PENDING`. Nenhuma arte
decorativa foi adicionada à superfície jurídica.

Analyzer e testes focais passaram; a suíte Flutter completa fechou
`1527 PASS + 1 skip governado` e `quality_gate.sh full` passou backend
determinístico, Flutter, Web público, auditoria, smoke e harnesses. Battle Live
e UX-PACKs 02–08 somam `22/22` manifests e `242/242` PNGs em `PASS_RUNTIME` no
digest `ebacfe42…`. Foram abertas 21 capturas diretamente afetadas nos três
breakpoints, sem overflow, arte coberta, campo estreito ou perda de CTA.
Project logic ficou sincronizado em `8/8`; `ui-audit` aprovou analyzer e
`56/56` testes antes de manter o fail-closed esperado da evidência global.

A aprovação global continua fail-closed. `latest.json` e os quatro perfis P0
com 214 capturas permanecem no digest `f45f96e3…`; a recaptura autenticada
exige PostgreSQL loopback descartável, proibido nesta atividade. A revisão
focal não foi transformada em revisão integral dos 242 PNGs atuais.

O relatório executável está em
[MANALOOM_UX_POLISH_RESPONSIVE_P2_IMPLEMENTATION_2026-08-07.md](MANALOOM_UX_POLISH_RESPONSIVE_P2_IMPLEMENTATION_2026-08-07.md).

Não resta implementação visual no P2. As próximas frentes são: revisão
jurídica externa; TalkBack/teclado físico/SM-A135M como gates de release; e
reancoragem dos 26 manifests/456 capturas somente após autorização explícita
da fixture PostgreSQL loopback. Localização estruturada, scanner físico,
progresso cross-device e mediação comercial continuam decisões próprias de
produto.
