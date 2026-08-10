# UX-PACK-01 — implementação da identidade de carta e impressão

**Início:** 2026-08-03
**Atualização:** 2026-08-05
**Estado:** `COMPLETE · GLOBAL_P0_PASS · UX_019_RESOLVED`
**Autorização:** sinais humanos “do que montou e organizou comece” e “pode fazer”
**Origem:** [MANALOOM_UX_IMPLEMENTATION_PACKETS_2026-08-03.md](MANALOOM_UX_IMPLEMENTATION_PACKETS_2026-08-03.md)

## Decisão

Esta rodada concluiu o `UX-PACK-01` nos destinos em que a pessoa precisa
reconhecer e confirmar carta ou impressão antes de decidir. O inventário de
callers, a fronteira `deck_cards`/cópia física, a política de arte e o reparo de
evidência `UX-019` foram fechados. O aggregate global voltou a `PASS`; conclusão
do pacote não concede aprovação de release global.

A composição usa arte da carta como âncora de reconhecimento, Frost para
metadados verificáveis da impressão e Brass somente para escolha, valor e ação.
A ordem é arte e nome → set e collector → disponibilidade ou estado físico →
ação. Fallback visual de outra impressão é rotulado como referência; a
aplicação não deve emprestar silenciosamente metadados nem escolher a primeira
impressão quando a escolha é material.

## Escopo implementado

| Superfície | Entrega |
|---|---|
| Busca de cartas e seletor de impressão | resultados agrupados abrem escolha visual quando há múltiplas impressões; confirmação exige escolha explícita; loading, vazio, erro e retry são recuperáveis |
| Deck detail e catálogo | commander, troca de edição, detalhe de set e cartas do deck preservam identidade de impressão e identificam arte de referência |
| Deck público da Comunidade | endpoint e UI entregam arte exata, set, collector, raridade e data da edição em ordem determinística |
| Sample hand | sete cartas reais, impressão focada, orientação Keep/Mulligan antes da leitura automática, estados vazio/curto e movimento reduzido |
| Optimize | preview e leitor mostram arte exata ou referência declarada, metadados e Oracle; remoção usa o ID de uma impressão realmente presente no deck |
| Binder | lista e editor mostram arte, set, collector, condição, idioma, quantidade, disponibilidade e acabamento físico; Card Search e Scanner entregam a impressão completa ao editor de criação; edição preserva ID desconhecido e não seleciona silenciosamente a primeira impressão |
| Marketplace e binder público | contratos hidratam impressão e UI combina arte, identidade física, disponibilidade, preço e sinais de confiança |
| Criar trade | itens desejados e oferecidos carregam arte e identidade física; quantidade oferecida é limitada às cópias livres |
| Detalhe do trade | perspectiva relativa “Você entrega/recebe”, arte, impressão, condição, idioma, foil, quantidade e valor antes de histórico e mensagens; a leitura usa snapshot imutável e não desaparece após edição ou remoção do Binder |
| Histórico do trade | migration `058_snapshot_trade_item_identity` captura atomicamente identidade de impressão e estado físico; legado recuperável é rotulado e legado sem fonte permanece legível como indisponível, sem inventar dados |
| Prova viva | segmento descartável cobre nove checkpoints novos em Web release 390×844, incluindo o fluxo real Search → Add do Binder, e estabiliza o primeiro frame após conversão da surface |

Backends hidratados nesta rodada:

- `/binder`;
- `/community/marketplace`;
- `/community/binders/:userId`;
- `/community/decks/:id`;
- `POST /trades`;
- `/trades/:id`;
- suporte de identidade de remoção em `/ai/optimize`.

## Semântica preservada

- `cards.foil` descreve capacidade da impressão no catálogo; não prova que
  uma cópia possuída ou uma carta do deck é foil.
- Condição, idioma e acabamento físico só aparecem onde o contrato possui
  esses dados, hoje principalmente Binder e Trades.
- `DeckCardItem.printingImageUrl` rejeita URL nomeada/oracle usada apenas como
  referência visual.
- A UI não inventa collector, idioma, acabamento ou câmbio para preencher
  lacunas. O Marketplace explicita quando compara anúncio BRL com referência
  USD sem conversão inferida.

## Evidência automatizada

- Flutter/Dart fixado na toolchain `3.44.6`;
- `16/16` testes focais da taxonomia de imagem aprovados;
- `44/44` testes focais de acabamento, carta, deck, Binder e Trade aprovados;
- `56/56` testes focais de deck aprovados;
- suíte completa do app: `1461` aprovados e `1` skip declarado;
- suíte completa local do servidor: `752` aprovados e `3` skips declarados;
- E2E social contra API real e PostgreSQL descartável: `2/2` aprovado,
  incluindo preservação do snapshot após editar e remover o item do Binder;
- `flutter analyze` completo do app: nenhum issue;
- `dart analyze` completo do servidor: nenhum issue;
- gate de schema descartável: `79` tabelas, `6` views, `98` FKs e `58`
  migrations alinhadas;
- contrato operacional de release: `27/27` verificações aprovadas.
- manifesto lógico regenerado e verificado: `664` arquivos Dart, `4923`
  símbolos, `12` regras de rastreabilidade e digest de fonte
  `92aa8d3051ba98f72349d210f27022373131cd48a8b92532bb3d94bcdc57c7f2`.

O E2E social produziu resumo em
`/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_server_contract_e2e_20260805T120502Z_51147/summary.txt`,
com migration `058`, egress não-loopback negado e cleanup registrado por trap.

Resultado focal: `PASS_AUTOMATED`.

O harness de importação agora aguarda e exige, antes da captura, a retenção de
`1 Sol Ring`, o status `1 cartas detectadas` e a presença do status no viewport.
O guard de política impede retirar essas assertivas silenciosamente. A suíte
focal adicional aprovou `23/23` testes. No digest `4f0194c3…`,
`manaloom_ui_live_evidence_gate.sh --check`, `quality_gate.sh ui-proof` e
`quality_gate.sh ui-audit` passaram; o último também aprovou analyzer e
`53/53` testes de inventário, teclado, estados e viewports.

## Evidência runtime e revisão visual

O build Web release real usou Chrome `150.0.7871.188`, viewport 390×844 e
PostgreSQL/API exclusivamente loopback e descartáveis.

| Manifest | Digest | Capturas | Resultado |
|---|---|---:|---|
| [adoções finais do UX-PACK-01](ui-live/current/ux-pack-01-completion-web/capture-manifest.json) | `6efb9f15…` | 9 | `PASS_RUNTIME · PASS_VISUAL_REVIEWED` |

As nove capturas foram abertas individualmente: criação e edição do Binder,
identidade física no Binder, Sample Hand, leitor do Optimize, Marketplace,
seleção desejada, seleção oferecida e detalhe do trade. A criação foi exercida
pelo fluxo real Binder → Card Search → impressão explícita → Add. A primeira
revisão detectou um frame Web quase
preto que a validação estrutural não recusava; a promoção foi bloqueada, o
harness passou a aguardar dois frames rasterizados e a captura release foi
repetida antes da decisão visual.

A revisão aprovou hierarquia, identidade MTG, contraste, tipografia,
espaçamento, adaptação 390×844, clareza da ação, cobertura de estados,
acessibilidade visual e atratividade. O registro detalhado e os hashes ficam no
manifest acima. A aprovação desse segmento é focal; a recaptura global abaixo
cobre Android físico e a matriz P0. TalkBack humano e teclado Web real
continuam verificações separadas de release.

### Recaptura global no digest vigente

A matriz P0 foi recapturada em build Web release real no digest
`4f0194c39d4e200787b0b6aeecd9390d9669d932ca690fa37e44b5f2420342f8`.
Cada PNG foi aberto individualmente e inspecionado por inteiro.

| Perfil | Viewport | Capturas | Runtime | Revisão visual desta rodada |
|---|---:|---:|---|---|
| Web mobile | 390×844 | 54/54 | `PASS_RUNTIME` | `PASS_VISUAL_REVIEWED` |
| Web desktop | 1440×900 | 53/53 | `PASS_RUNTIME` | `PASS_VISUAL_REVIEWED` |
| Web wide | 1920×1080 | 53/53 | `PASS_RUNTIME` | `PASS_VISUAL_REVIEWED` |
| Android físico | SM-A135M · Android 14 · 1080×2408 | 54/54 | `PASS_RUNTIME` | `PASS_VISUAL_REVIEWED` |
| Battle Live Web | 1440×900 | 5/5 | `PASS_RUNTIME` | `PASS_VISUAL_REVIEWED` |

As `214` capturas da matriz P0 — `160` Web e `54` Android físico — e as cinco
capturas Battle Live foram abertas individualmente. Não apresentaram
sobreposição, corte estrutural ou ação principal inacessível. A inspeção
confirmou, porém, oportunidades já ligadas aos pacotes preparados:

- Gerar/Importar Deck, onboarding, Battle/replay e pós-jogo continuam muito
  textuais para os jobs de Magic que deveriam ancorar;
- Battle Live nomeia cartas na timeline, mas não mostra carta ou zona visual;
- estados vazios de Seguindo, Mensagens, Notificações e Trades explicam a
  ausência sem oferecer a próxima ação contextual;
- perfis continuam representando a pessoa principalmente por uma inicial;
- o resumo da coleção é denso e trunca métricas em desktop;
- no pós-jogo wide, `Reconstruir` quebra de linha de forma ruim;
- carrosséis horizontais de métricas, filtros e abas no Android cortam o
  próximo item sem affordance suficiente de continuidade;
- o fixture repete a mesma miniatura em várias cartas, portanto comprova
  layout/fallback, mas não a riqueza visual de um catálogo real.

O perfil físico foi executado no Samsung `SM-A135M`, Android 14, serial
`R58T300SREH`, com `54/54` checkpoints e Life Counter nativo em landscape. As
54 imagens foram abertas. Nos quatro perfis P0, `deck_import_detected.png`
agora mostra `1 Sol Ring`, `1 cartas detectadas` e o CTA `Criar Deck` no mesmo
viewport. Os quatro manifests P0 e o de Battle Live foram compostos com hashes
exatos no [aggregate corrente](ui-live/latest.json), que passou com 219
capturas e os três níveis `PASS_AUTOMATED`, `PASS_RUNTIME` e
`PASS_VISUAL_REVIEWED`. O manifesto antigo do emulador permanece apenas como
histórico recuperável no Git e não recebeu crédito corrente.

O [progresso visual do Battle Live](ui-live/reference/2026-08-03-battle-live-progress/README.md)
foi preservado e consultado somente como referência; o pacote não alterou nem
reclassificou essa superfície.

## Fechamentos desta continuação

- Card Search e Scanner agora entregam ao editor do Binder o mapa completo da
  impressão escolhida. O editor mantém essa identidade visível mesmo quando a
  consulta suplementar falha ou não devolve correspondência.
- `trade_items` agora possui snapshot versionado e imutável. A criação captura
  carta, impressão, arte, condição, idioma e foil dentro da mesma transação que
  bloqueia as cópias; o detalhe lê snapshot primeiro e usa Binder vivo apenas
  como compatibilidade para legado.
- Editar condição/idioma ou remover o item do Binder não altera nem apaga a
  memória de um trade concluído. Linhas legadas sem identidade recuperável são
  declaradas como indisponíveis, sem preencher campos inventados.
- `CardArtwork` e `CachedCardImage` agora expõem estados distintos de loading,
  imagem exata, referência, ausência, baixa resolução, falta de conexão
  explicitamente informada e erro; sem conexão nunca é inferida de uma falha
  genérica de rede.
- O ADR 0008 fecha a fronteira entre decklist e inventário: `cards.foil` é
  disponibilidade de catálogo, enquanto idioma e acabamento da cópia
  pertencem ao Binder. A UI usa rótulos diferentes para não transformar uma
  capacidade da impressão em fato físico.
- O [contrato de origem, cache e direitos de arte](../MANALOOM_CARD_ART_SOURCE_CACHE_AND_RIGHTS_CONTRACT.md)
  fixa imagem completa em `contain`, proíbe `art_crop` no produto, limita
  cache/retry/rate e bloqueia monetização com dados ou imagens de carta até
  revisão jurídica externa.
- O inventário de callers foi fechado: Scanner usa `CardArtwork`, os callers
  diretos de carta ficam centralizados em `CachedCardImage` e os providers de
  rede remanescentes são apenas avatares em allowlist testada.

## Escopo fechado e itens replanejados

1. A adoção da taxonomia compartilhada foi inventariada e protegida por guard;
   não restam callers diretos de imagem de carta fora do núcleo compartilhado.
2. `deck_cards` permanece corretamente uma decklist com identidade da impressão
   do catálogo. Condição, idioma e acabamento de cópia pertencem ao Binder e ao
   snapshot de Trade, conforme ADR 0008; expandir `deck_cards` para fingir posse
   física não é requisito deste pacote.
3. Generate/import, onboarding, Battle/replay, pós-jogo, vazios, perfis e wide
   continuam como escopo explícito dos pacotes 02–08. Eles são backlog preparado,
   não critério residual do `UX-PACK-01`.
4. Origem, crédito, cache, tratamento visual e direitos foram fechados para a
   beta gratuita no contrato específico. Monetização ou mudança de fonte reabre
   revisão jurídica e de produto.
5. TalkBack humano, smoke de hardware/release e teclado Web real permanecem
   gates separados de release; não recebem crédito desta rodada e não bloqueiam
   a conclusão do pacote de implementação.

## Limites e cleanup

- a migration `058_snapshot_trade_item_identity` foi declarada e provada
  somente no PostgreSQL isolado; não foi aplicada em ambiente live;
- nenhuma escrita live, alteração de regra/Oracle, promoção de deck, runtime de
  produção, deploy, commit ou push;
- a única escrita de runtime ocorreu no PostgreSQL descartável e loopback da
  fixture de evidência;
- cleanup comprovado em
  `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_visual_qa/20260805T114105Z_33711_11651/cleanup-summary.json`:
  banco remanescente 0, listeners Web/API 0 e credenciais removidas;
- a fixture global desta recaptura também terminou por trap controlado, com
  `database_remaining=0`, listeners Web/API 0 e credenciais removidas em
  `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_visual_qa/20260805T125923Z_93388_12182/cleanup-summary.json`;
- a fixture do reparo `UX-019` terminou por trap controlado, com
  `database_remaining=0`, listeners Web/API 0 e credenciais removidas em
  `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_visual_qa/20260805T142318Z_62922_9437/cleanup-summary.json`;
- a recaptura final no digest `4f0194c3…` terminou por trap controlado, com
  `database_remaining=0`, listeners Web/API 0 e credenciais removidas em
  `/var/folders/33/24q27rwn2v5_h9gfctty7t_40000gn/T/manaloom_visual_qa/20260805T153915Z_13435_11917/cleanup-summary.json`;
- as alterações preexistentes de SwiftPM/iOS foram preservadas.

## Conclusão do pacote

Os critérios do `UX-PACK-01` estão satisfeitos ou formalmente replanejados para
os pacotes donos: identidade de impressão, fallback, DFC/geometria, semântica,
fonte/direitos e adaptação P0 têm prova automatizada, runtime e visual no digest
corrente. O pacote está `COMPLETE`; esse fechamento remove o bloqueio `UX-019`,
mas não autoriza release nem inicia outro pacote.
