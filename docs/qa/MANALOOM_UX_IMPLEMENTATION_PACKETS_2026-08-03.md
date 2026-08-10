# Pacotes de implementação — auditoria UX integral do ManaLoom

**Preparados em:** 2026-08-03
**Estado global:** `UX_PACKS_01_08_COMPLETE_LOCAL · UX_PACK_08_FOCAL_WEB_PASS · GLOBAL_UI_REANCHOR_REQUIRED`
**Relatório de origem:** [MANALOOM_FULL_PRODUCT_UX_AUDIT_REPORT_2026-08-03.md](MANALOOM_FULL_PRODUCT_UX_AUDIT_REPORT_2026-08-03.md)

O `UX-PACK-01` recebeu autorização humana explícita em 2026-08-03 pelo sinal
“do que montou e organizou comece”, reiterada em 2026-08-05 por “pode fazer”. A
autorização cobriu a implementação progressiva desse pacote. O `UX-PACK-02`
foi iniciado em 2026-08-05 após “pode seguir para os proximos passos”, com a
decisão de importar em lote primeiro e reutilizar a mesma fila para scanner sob
feature flag. As continuações “okay então pode prosseguir”, “continue” e
“okay continue” autorizaram os pacotes 03–05; as continuações posteriores
autorizaram e concluíram os pacotes 06 e 07 em 2026-08-06. As continuações
seguintes autorizaram e concluíram o Pack 08 no escopo local/focal. Nenhum
desses sinais autoriza release,
reancoragem global, migration, deploy, commit ou push; toda execução permanece
sujeita aos contratos E2E e de evidência visual.

## Princípios comuns

- PostgreSQL/backend continua sendo a verdade; Hermes/SQLite é cache/laboratório.
- Card art deve ajudar reconhecimento ou decisão e respeitar impressão, fallback, crédito e política da fonte.
- Toda mutation de IA/import/scanner/trade precisa de preview, confirmação, erro recuperável e idempotência.
- Nenhuma recomendação de IA substitui legalidade, Oracle ou decisão humana.
- Toda mudança app-facing exige `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED` no digest novo.
- TalkBack humano, teclado Web real e smoke Android de hardware/release continuam verificações separadas de release.

## Mapa de dependências

```text
UX-PACK-08 evidência-base
        │
        ├── UX-PACK-01 identidade/printing ──┬── UX-PACK-02 coleção
        │                                    ├── UX-PACK-03 deck/IA
        │                                    ├── UX-PACK-04 partida/aprendizado
        │                                    └── UX-PACK-05 comunidade/trade
        │
        └── UX-PACK-06 onboarding/Home ─────── UX-PACK-07 visual/wide
```

O diagrama expressa dependência conceitual, não obriga execução estritamente serial. `UX-PACK-08` pode preparar a prova enquanto `UX-PACK-01` define o contrato de identidade visual.

## UX-PACK-01 — identidade de carta e printing

**Prioridade:** P1
**Onda:** 2, transversal às ondas 3–5
**Estado:** `COMPLETE · GLOBAL_P0_PASS · UX_019_RESOLVED`
**Implementação corrente:** [MANALOOM_UX_PACK_01_IMPLEMENTATION_2026-08-03.md](MANALOOM_UX_PACK_01_IMPLEMENTATION_2026-08-03.md)
**Autorização:** 2026-08-03, “do que montou e organizou comece”; reiterada em 2026-08-05, “pode fazer”

### Objetivo

Fazer a mesma carta/impressão permanecer reconhecível e verificável em busca, coleção, deck, set, optimize, comunidade, trade e playtest.

### Findings

`UX-003`, `UX-005`, parte de `UX-006` e `UX-009`.

### Wireflow proposto

```text
resultado Oracle
  → escolher impressão quando relevante
  → confirmar set / collector / idioma / finish / condição
  → mostrar a mesma identidade no destino
  → fallback honesto com status da imagem
  → trocar impressão sem remover o objeto inteiro
```

### Tese visual

- Modo `visual`: thumbnail/frame consistente para reconhecimento.
- Modo `compacto`: nome, mana, set, collector, finish, idioma, quantidade e disponibilidade.
- Reader sob demanda; não abrir modal em toda interação.
- Arte genérica ManaLoom é fallback explícito, nunca representação silenciosa da impressão.

### Escopo provável

- `CachedCardImage`, `CardArtwork`, políticas Scryfall/cache;
- card search/detail;
- deck list/detail/cards/sample hand;
- binder editor/search e marketplace;
- sets/set detail;
- optimize add/cut/reader;
- community deck, user binder e trade item picker.

### Pacote concluído em 2026-08-05

- contrato compartilhado adotado em busca/printing picker, deck detail,
  catálogo, Comunidade, Sample Hand, Optimize, Binder, Marketplace e Trades;
- Search/Scanner entregam a impressão completa ao editor de criação do Binder;
- `POST /trades` captura snapshot imutável da impressão e do estado físico; o
  detalhe permanece legível após edição ou remoção do item no Binder;
- suítes completas de `1461` app + `1` skip e `752` servidor + `3` skips,
  além de `2/2` E2E social, aprovadas com Flutter/Dart 3.44.6 fixado;
- nove checkpoints Web release 390×844 no digest `6efb9f15…` receberam
  `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED` focal;
- ADR 0008 fecha `deck_cards` como decklist e mantém identidade de cópia física
  no Binder; a taxonomia compartilhada de fallback foi implementada em
  `CardArtwork`/`CachedCardImage`;
- inventário/guard fecham os callers diretos de imagem de carta e proíbem
  `art_crop`; origem, cache, crédito e direitos estão no contrato específico;
- matriz global no digest `4f0194c3…`: 214 capturas P0 + 5 Battle Live,
  todas abertas, com `PASS_AUTOMATED`, `PASS_RUNTIME` e
  `PASS_VISUAL_REVIEWED`;
- destinos textuais, vazios, perfil, Battle e wide foram atribuídos aos pacotes
  02–08 e não permanecem como dívida de conclusão do pacote 01.

### Critérios de aceite

- duas impressões de mesmo Oracle ID são distinguíveis antes de salvar;
- edição existente pode trocar impressão com preview e validação;
- deck list, detalhe, sample hand e comunidade mostram a mesma identidade esperada;
- estados `missing`, `placeholder`, `lowres`, `highres`, offline e erro são distintos;
- DFC, crop, aspect ratio e semântica têm testes;
- Web 390/1440/1920 e Android atual mostram visual e compacto sem overflow;
- fontes/licenças/créditos são validados.

### Não objetivos

- criar scanner;
- alterar regra/Oracle;
- transformar segurança/legal em telas com arte decorativa.

## UX-PACK-02 — ingestão e organização da coleção

**Prioridade:** P1
**Onda:** 2
**Estado:** `PHASE_1_COMPLETE_LOCAL · FOCAL_WEB_PASS_RUNTIME · FOCAL_WEB_PASS_VISUAL_REVIEWED · GLOBAL_UI_EVIDENCE_PASS · LOCATION_MIGRATION_PENDING`
**Decisão tomada:** ambos em fases; lote por texto primeiro, scanner na mesma
fila sob feature flag e localização somente após autorização separada de
migration.
**Implementação corrente:** [MANALOOM_UX_PACK_02_IMPLEMENTATION_2026-08-05.md](MANALOOM_UX_PACK_02_IMPLEMENTATION_2026-08-05.md)
**Contrato:** [MANALOOM_COLLECTION_INGESTION_CONTRACT.md](../MANALOOM_COLLECTION_INGESTION_CONTRACT.md)
**Autorização:** 2026-08-05, “pode seguir para os proximos passos”

### Objetivo

Permitir que jogador retornando ou colecionador cadastre muitas cartas com revisão segura, corrija ambiguidades e saiba onde cada cópia está.

### Findings

`UX-002`, `UX-003`, `UX-004`.

### Wireflow proposto

```text
Coleção vazia
  → importar arquivo/texto OU iniciar sessão de scanner
  → fila de candidatos
  → ambiguidades e duplicatas destacadas
  → corrigir printing / finish / idioma / condição / localização
  → resumo total / alocada / livre / faltante
  → aplicar lote
  → histórico + retry por item
```

### Tese de conteúdo

- Separar claramente `tenho`, `quero`, `alocada`, `livre`, `em troca` e `faltante`.
- Localização estruturada: área, caixa/fichário e posição opcional; nota continua livre.
- Mostrar o que será criado, atualizado, ignorado ou rejeitado antes de persistir.

### Critérios de aceite

- draft local por usuário e retomada após fechamento/offline;
- ambiguity queue nunca escolhe silenciosamente a primeira impressão;
- lote é idempotente e tem resumo por item;
- falha parcial preserva candidatos e oferece retry;
- alteração de printing em item existente é possível;
- owned/allocated/free/missing reconcilia com o backend;
- prova runtime cobre lote pequeno, duplicata, erro, retry, cancelamento e sucesso.

### Riscos/dependências

- contrato de localização e import format;
- câmera/ML Kit e escopo Web/Android;
- Scryfall rate/cache;
- eventual migration precisa de autorização separada.

### Fase sem migration implementada em 2026-08-05

- `/collection/import` entrega workspace persistente, draft por usuário,
  parser/hints, ambiguidades, duplicatas, correção física e histórico local;
- `POST /binder/import/preview` é read-only e produz baseline/target mais
  `create/update/rejected` e disponibilidade backend;
- `POST /binder/import/apply` aplica por identidade com compare-and-set,
  reconhece replay e preserva falhas para retry;
- scanner contínuo alimenta a mesma fila somente quando
  `ENABLE_SCANNER_RELEASE=true`;
- item existente pode trocar impressão por `card_id` validado;
- localização estruturada não foi simulada em `notes` e mantém o pacote global
  aberto até decisão/migration autorizada;
- runtime focal Web release foi capturado em 390x844, 1440x900 e 1920x1080:
  21 PNGs no digest
  `3bf0cbbd97df6123469eb2e3481cc549fa240e92b2a3339b920dd86b7f69bbd3`
  foram abertos e receberam `PASS_VISUAL_REVIEWED`;
- a prova focal não substitui a matriz P0 global, scanner em Android físico,
  TalkBack humano, teclado Web real ou autorização de migration/release.

## UX-PACK-03 — workshop de deck e IA verificável

**Prioridade:** P1
**Onda:** 3
**Estado:** `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_PASS`.

### Objetivo

Transformar geração, importação, análise e optimize em uma oficina contínua em que o jogador entende e aprova cada mudança.

### Findings

`UX-006`, `UX-007`, `UX-009`, `UX-010`.

### Wireflow proposto

```text
objetivo do jogador
  → commander/tema visual e validado
  → restrições: formato, bracket, orçamento, coleção, cartas âncora
  → proposta ou import preflight
  → pares adicionar ↔ cortar
  → motivo / fonte / impacto / confiança
  → seleção parcial
  → validação determinística
  → snapshot + aplicar
  → histórico persistente / undo / rollback
  → sample hand ou Battle com a revisão nova
```

### Tese visual

- Commander e cartas âncora abrem a narrativa.
- Recomendações são pares de cartas, não listas independentes.
- Antes/depois responde curva, funções, custo, coleção e bracket.
- Reader de carta fica disponível sem interromper a seleção.
- Fontes indisponíveis são resumidas; sete linhas `Não disponível` não dominam a tela.

### Critérios de aceite

- comandante é selecionado por objeto canônico, não somente texto livre;
- import mostra reconhecida/ambígua/desconhecida antes de criar;
- toda sugestão tem motivo e origem, ou declara ausência;
- legalidade, identidade, tamanho e orçamento são validados fora da IA;
- apply exige assinatura esperada do deck e detecta conflito;
- histórico lista evento, revisão, escolhas e undo disponível;
- teste demonstra partial selection, conflito, apply e rollback;
- captura visual inclui add/cut, reader, fonte/confiança e erro recuperável.

### Não objetivos

- prometer deck ideal;
- usar score único como verdade;
- executar compra ou trade automaticamente.

### Resultado implementado em 2026-08-05

- geração ganhou seleção visual do objeto canônico do comandante sem remover a
  compatibilidade do campo textual;
- import passou a executar preflight real antes da criação e mostra cartas
  reconhecidas, matches localizados, linhas não identificadas e CTA explícito
  de rascunho quando há pendências;
- Optimize passou a selecionar mudanças como pares `sai ↔ entra`, com motivo,
  papel, risco, confiança, custo/coleção, fonte e reader de carta;
- a nova aba `Oficina` organiza comandante, objetivo, trocas, validação e teste,
  e lê o histórico owner-scoped do PostgreSQL;
- undo saiu do snackbar efêmero: a ação permanece no evento aplicável e o
  conflito por edição posterior aparece inline sem sobrescrever mudanças;
- o backend ganhou somente a leitura sanitizada
  `GET /decks/:id/optimizations`; nenhuma migration, pin, runtime ou escrita
  live foi necessária;
- a prova focal Web release cobriu 390x844, 1440x900 e 1920x1080: 24 PNGs no
  digest `80205a33a8784b44c4a9aceee6345aabc01c2dfd8bcd1eb1dca296a516e23a65`
  foram abertos individualmente e receberam `PASS_VISUAL_REVIEWED`;
- esta conclusão é local e focal: não substitui a matriz P0 global, Android
  físico, TalkBack humano, teclado Web real, PostgreSQL live ou autorização de
  release.

## UX-PACK-04 — partida, replay e aprendizado do deck

**Prioridade:** P1
**Onda:** 4
**Estado:** `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_PASS`.

### Objetivo

Fazer a partida iniciada no ManaLoom retornar como evidência estruturada para a próxima decisão de deck.

### Findings

`UX-001`, `UX-008`, `UX-017`.

### Wireflow proposto

```text
Home ou deck
  → escolher deck/revisão ou modo rápido
  → iniciar/retomar/nova partida explicitamente
  → Life Counter ou Battle
  → concluir / registrar resultado
  → selecionar cartas reais do deck + issues
  → resumo ligado à revisão
  → Optimize recebe note_id, issues e cartas
  → recomendação mostra quais evidências usou
  → testar nova revisão
```

### Tese visual

- Life Counter mantém vida como elemento dominante; arte de comandante é opt-in.
- Battle Live mostra mesa/zonas/timeline e cards quando IDs existirem, com modo textual acessível.
- Pós-jogo mostra cartas do deck como seleção compacta com thumbnail, não campos de nomes livres.

### Critérios de aceite

- Home oferece seleção de deck antes da partida ou declara modo sem deck;
- saída diferencia retomar, encerrar e começar nova sessão;
- pós-jogo preserva session/revision/note e funciona offline-first;
- Optimize recebe e exibe evidências escolhidas;
- replay/annotation e pós-jogo não formam lanes incompatíveis;
- sem card ID, UI não inventa arte nem inferência;
- estados reconexão, timeout, conclusão e retorno são capturados.

### Resultado implementado em 2026-08-05

- Home passou a exigir escolha explícita de deck/revisão ou modo rápido sem
  deck, além de separar retomar de encerrar e registrar;
- o handoff preserva sessão, timestamps, hash e versão da revisão;
- Battle Live ganhou mesa, zonas e timeline com arte somente para UUID exato em
  dados públicos, mantendo fallback textual honesto;
- replay permaneceu imutável e ganhou handoff explícito para anotação pós-jogo;
- o pós-jogo passou a selecionar cartas reais do deck em estados
  `Preservar/Revisar`, com issues estruturadas, recibo e fila offline-first;
- divergência entre a revisão histórica solicitada e o deck carregado bloqueia
  a seleção, em vez de atribuir sinais à lista errada;
- Optimize recebe apenas `post_game_note_id`; o backend reabre e canonicaliza a
  evidência por usuário, deck, nota e revisão antes de expô-la no preview;
- notas livres e zonas privadas não entram na recomendação, e evidência não
  concede aplicação automática;
- a prova focal em Chrome release cobriu 390x844, 1440x900 e 1920x1080: 30
  capturas foram abertas individualmente e receberam
  `PASS_VISUAL_REVIEWED` no digest UI
  `93009fc2a9215288336406015b4583473c8520b75c409f9214852cec607452df`;
- o harness entrou na política/digest oficial sob os perfis exclusivos
  `web_battle_learning_*`, sem colisão com a matriz P0;
- esta conclusão é local e focal; matriz P0 global, Android físico, TalkBack,
  teclado Web real, PostgreSQL live e release não são promovidos por este
  pacote.

## UX-PACK-05 — comunidade, faltantes e trades acionáveis

**Prioridade:** P1
**Onda:** 5
**Estado:** `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_STALE`.
**Implementação corrente:** [MANALOOM_UX_PACK_05_IMPLEMENTATION_2026-08-06.md](MANALOOM_UX_PACK_05_IMPLEMENTATION_2026-08-06.md)
**Autorização:** 2026-08-06, continuidade explícita — “pode seguir para os
proximos passos”, “continue” e “okay continue”.

### Objetivo

Preservar carta, deck e pessoa desde a descoberta de uma falta até conversa, proposta e conclusão.

### Findings

`UX-004`, `UX-009`, `UX-013` e parte de `UX-015`.

### Wireflow proposto

```text
deck com faltantes
  → ver cópia necessária
  → ofertas/matches relevantes
  → perfil e reputação contextual
  → proposta com carta e tipo na URL/estado recuperável
  → conversa ancorada na proposta
  → comparação do que quero/ofereço
  → confirmar/finalizar
  → atualizar disponibilidade
```

### Decisões de arquitetura

- Marketplace canônico em `/collection?tab=1`, com `/marketplace` como alias;
- Cotações em `/community?tab=3`, com `/quotes` e `/market` legado como aliases;
- comentários preservam contexto sanitizado em envelope textual compatível,
  sem migration;
- proposta preserva receiver, item, tipo, source, deck e contraproposta na URL;
- PostgreSQL revalida cópia física pública, visibilidade, bloqueios e
  disponibilidade; estado de navegação nunca concede autorização;
- contraproposta automática fica restrita a troca pura e substitui a proposta
  pendente atomicamente.

### Critérios de aceite

- reload/share de create trade mantém receiver, item e tipo;
- match de comunidade possui CTA e IDs suficientes;
- empty states de Ofertas, Trocas, Usuários e Mensagens têm ação contextual;
- cards mostram printing/condição/preço/freshness quando relevantes;
- privacidade e quem pode ver cada informação são claros;
- proposta, contraproposta, rejeição, erro e finalização têm prova atual.

### Resultado implementado em 2026-08-06

- o caminho faltante → match → Marketplace → proposta é acionável e preserva
  a cópia pública exata;
- reload/share reconstrói a proposta pela URL, e busca de usuários restaura a
  query pública;
- cards de match/oferta mostram arte, printing, estado físico, preço,
  disponibilidade, pessoa e freshness quando aplicáveis;
- comentários públicos podem ser ancorados no deck, categoria ou carta e
  continuam compatíveis com registros legados;
- empty states de matches, Marketplace, trades, mensagens e usuários possuem
  próxima ação contextual;
- contraproposta de troca pura é transacional, revalida disponibilidade e
  libera a reserva anterior sem migration;
- a correção responsiva solicitada pelo usuário passou a usar a largura local
  do card; o CTA mobile ocupa mais de 300 px e possui teste de regressão;
- 48 capturas Web release, em 390×844, 1440×900 e 1920×1080, foram abertas
  individualmente e receberam `PASS_VISUAL_REVIEWED` no digest
  `70322d0704bc63fffe5520d1874873c100c3d82ddb85e8f9cf53ccd288083adf`;
- a conclusão é local/focal; a matriz agregada permanece fail-closed até
  reancoragem integral no digest corrente.

## UX-PACK-06 — onboarding e Home orientados por intenção

**Prioridade:** P1/P2
**Onda:** 1
**Estado:** `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_STALE`.

### Objetivo

Fazer o primeiro uso começar pelo objetivo do jogador e terminar com um próximo passo real, não com três painéis informativos.

### Findings

`UX-007`, parte de `UX-008` e `UX-013`.

### Wireflow proposto

```text
primeiro acesso
  → objetivo: catalogar / montar / importar / jogar / melhorar
  → formato e experiência
  → comandante/deck/lista visual quando aplicável
  → executar uma tarefa curta
  → concluir onboarding
  → Home mostra próximo passo daquele objetivo
```

### Tese visual

- Usar imagem real somente nos caminhos de carta/deck/comandante.
- Trocar cards homogêneos por uma sequência com progressão visível.
- Home continua enxuta e usa uma única ação principal contextual.

### Critérios de aceite

- gerar/importar/criar conclui ou atualiza onboarding de forma explícita;
- `from=onboarding` é consumido ou removido;
- progresso importante não depende apenas de SharedPreferences se precisa ser cross-device;
- usuário pode pular e retomar sem perder intenção;
- persona iniciante entende diferença entre gerar, importar e criar;
- provas incluem first-run, resume, skip e retorno com deck criado.

### Resultado implementado em 2026-08-06

- objetivo, experiência, formato e método agora formam uma jornada progressiva
  e persistida por usuário/dispositivo;
- catalogar, criar manualmente, gerar e importar recebem rotas exatas com
  `from=onboarding`; conclusão só ocorre após sucesso real da tarefa;
- jogar e melhorar continuam pendentes até a entrada em mesa ou Optimize com
  deck real, sem usar um deck preexistente como falsa conclusão;
- skip, retomada, falha/retry e retorno contextual à Home foram cobertos;
- 15 capturas Web release, em 390×844, 1440×900 e 1920×1080, foram abertas
  individualmente e receberam `PASS_VISUAL_REVIEWED` no digest
  `5df01bcd9322d7bd5809ae5c15bd6f592e4871a5c247a014a2689f854b68abd7`;
- o progresso cross-device permanece decisão futura: o pacote não criou
  contrato backend nem migration para fingir essa capacidade;
- a conclusão é local/focal; a matriz agregada permanece fail-closed até a
  reancoragem integral no digest corrente.

## UX-PACK-07 — sistema visual interno e layout wide

**Prioridade:** P2
**Onda:** 7, depois dos fluxos P1
**Estado:** `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_STALE`.

### Objetivo

Reduzir aparência de dashboard genérico sem sacrificar densidade e transformar desktop/wide em workspace real.

### Findings

`UX-013`, `UX-014`, `UX-015`, `UX-016`, `UX-018`.

### Direções

- Painel/card só quando representar entidade ou grupo interativo.
- Seções de settings usam divisores e navegação interna, não cards aninhados.
- Wide usa mestre/detalhe, painel lateral, comparação ou inspector quando o job pedir.
- Empty state diferencia `primeiro uso`, `resultado zero`, `erro`, `offline` e `indisponível`.
- Perfil separa identidade de jogador de conta/segurança.
- Barra de quota usa um modelo único: `usado` ou `restante`.
- Save fica disabled sem dirty state e comunica saving/success/error inline.

### Critérios de aceite

- 1920×1080 recompõe a tarefa, não apenas centraliza a coluna mobile;
- cards empilhados são reduzidos sem perder agrupamento;
- modos visual/compacto preservam função;
- empty states oferecem CTA somente quando há ação real;
- contraste de componentes e foco atendem o contrato;
- screenshots top/below-fold mostram densidade apropriada nos três viewports.

### Entrega concluída em 2026-08-06

- Profile foi recomposto como bancada de jogador: rail de identidade à
  esquerda e tarefa/configuração à direita no wide, com conta e segurança
  separadas;
- perfil público ganhou identidade, contexto social, deck em destaque e arte
  governada; as quatro abas cabem no mobile;
- primeiro deck virou workspace de escolha, e os estados `first use`, zero
  resultados, erro, offline e indisponível receberam linguagem própria;
- quota de IA adotou o modelo único de ações usadas;
- Save passou a depender de dirty state e comunica saving/success/error inline;
- `44/44` testes focais passaram; três builds Web release produziram `30/30`
  capturas no digest `a408c2a3…`, todas abertas individualmente e aprovadas;
- o resultado focal não promove `latest.json`; a matriz global corrente exige
  26 manifests/453 capturas e continua fail-closed até reancoragem integral.

Relatório:
[MANALOOM_UX_PACK_07_IMPLEMENTATION_2026-08-06.md](MANALOOM_UX_PACK_07_IMPLEMENTATION_2026-08-06.md).

## UX-PACK-08 — evidência, estados e acessibilidade

**Prioridade:** P1 de governança
**Onda:** 0/7
**Estado:** `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_STALE`
**Implementação corrente:** [MANALOOM_UX_PACK_08_IMPLEMENTATION_2026-08-06.md](MANALOOM_UX_PACK_08_IMPLEMENTATION_2026-08-06.md)
**Autorização:** 2026-08-06, continuações explícitas até “continue”

### Objetivo

Fazer a prova visual representar as jornadas e riscos reais, não somente um conjunto P0 acima da dobra.

### Findings

`UX-011`, `UX-012`.

### Escopo

- contrato, política e `UI_TEST_SURFACE_MAP.md` reconciliados para a superfície
  `critical_overlays_states`;
- 22 checkpoints ligados a estado → source → anchor → teste → fluxo → estágio →
  política de mutation;
- action-open-error/recovery/final comprovado em Profile, Decks, Commander,
  Fichário, Trades e estados transversais;
- below-fold de segurança, loading/error/retry/recovered, validações, cancelamento
  destrutivo, printing exata, save/submit error, session-expired e
  permission-denied cobertos;
- 66 capturas Web release finais abertas e aprovadas;
- teclado Web real, Android físico, TalkBack humano e aggregate global mantidos
  como gates separados de release.

### Prioridade de overlays

1. excluir conta/deck, revogar sessões e conceder partida;
2. optimize preview/apply/undo/conflict;
3. collection editor, printing e falha/retry;
4. create deck e commander picker;
5. trade item picker e confirmação;
6. avatar, blocked users e password/session dialogs;
7. card reader/fallback e Battle Coach.

### Critérios de aceite

- nenhum manifesto stale recebeu crédito;
- os três manifests focais usam o digest `60bbef19…`, 22 checkpoints e runtime
  Web real;
- cada estado focal tem anchor, teste relevante e hash de execução;
- `55/55` testes e analyzer focal passaram;
- `66/66` capturas declaradas foram abertas depois da recaptura final;
- `PASS_VISUAL_REVIEWED` não substitui TalkBack, teclado real ou hardware;
- fixture descartável/em memória, sem escrita live.

## Ordem de autorização sugerida

| Ordem | Pacote | Motivo |
|---:|---|---|
| 1 | `UX-PACK-01` | base compartilhada de reconhecimento e printing |
| 2 | `UX-PACK-08` | amplia a prova antes de mudanças maiores |
| 3 | `UX-PACK-02` | fecha dor de ingestão/posse |
| 4 | `UX-PACK-03` | transforma IA em workshop verificável |
| 5 | `UX-PACK-04` | fecha o diferencial partida → aprendizado |
| 6 | `UX-PACK-05` | torna faltantes/social/trades acionáveis |
| 7 | `UX-PACK-06` | melhora ativação com os fluxos centrais definidos |
| 8 | `UX-PACK-07` | consolida refinamento visual e wide |

A ordem foi concluída até o `UX-PACK-08`: ativação, fluxos P1, recomposição
visual e a prova focal de estados críticos foram fechados localmente. A próxima
etapa é congelamento e reancoragem global `26/453`; nenhuma prova focal promove
o aggregate automaticamente.

## Anexo — POLISH-RESPONSIVO-P2

**Prioridade:** P2 de experiência + governança
**Estado:** `COMPLETE_LOCAL · AUTOMATED_FULL_PASS · FOCAL_WEB_VISUAL_PASS · LEGAL_REVIEW_EXTERNAL_PENDING · GLOBAL_REANCHOR_INCOMPLETE`
**Implementação corrente:** [MANALOOM_UX_POLISH_RESPONSIVE_P2_IMPLEMENTATION_2026-08-07.md](MANALOOM_UX_POLISH_RESPONSIVE_P2_IMPLEMENTATION_2026-08-07.md)
**Autorização:** 2026-08-07, “continue”

### Escopo concluído

- continuidade explícita para cartas, printings e evidências, com controles
  fora da arte;
- Sample Hand com posição, gesto e setas;
- nome de jogador longo em duas linhas, semântica e tooltip integrais;
- fixtures distintas para comandante, mão inicial e evidência pós-jogo;
- auditoria da composição de Legal/Privacy sem reescrever copy jurídica;
- 22 manifests determinísticos/242 PNGs atualizados no digest final;
- 21 capturas diretamente afetadas abertas em mobile, desktop e wide.

### Critérios atendidos

- nenhum overlay cobre, recorta ou distorce card art;
- controle horizontal só aparece quando existe overflow;
- teclado/semântica e movimento reduzido possuem contratos automatizados;
- nome longo não causa overflow e continua integralmente acessível;
- fixture não recebe crédito de printing oficial;
- Legal permanece sóbrio e a revisão jurídica é declarada como externa;
- o aggregate global não recebe crédito enquanto P0/review estiverem stale.

### Fora do pacote

- revisão jurídica da copy;
- TalkBack humano, teclado Web físico e smoke no Samsung;
- recaptura P0 autenticada, pois exige autorização de PostgreSQL loopback;
- localização estruturada, scanner físico, progresso cross-device e mediação
  financeira/comercial.

A reancoragem global passa a exigir 26 manifests/456 capturas, porque o
checkpoint de continuidade do Sample Hand acrescentou uma captura em cada um
dos três perfis do Deck Workshop.
