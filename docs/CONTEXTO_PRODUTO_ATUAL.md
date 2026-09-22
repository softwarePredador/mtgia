# Contexto Produto Atual

> A decisão curta que prevalece para escopo, oferta e release está em
> `docs/status/CURRENT_PRODUCT_DECISION.md`. O backlog mestre define a ordem de
> execução e `docs/MANALOOM_E2E_RELEASE_CONTRACT.md` define validação e
> conclusão. A fila WIP 1, o contrato de fechamento e as fichas ficam em
> `docs/execution/CURRENT_QUEUE.md` e `docs/execution/README.md`. O restante
> deste arquivo preserva contexto por data.

## Decisão vigente — 2026-08-25

- estado: `NO_GO_PUBLIC_RELEASE`;
- candidato pretendido: beta gratuita, coorte controlada, Web + Android;
- oferta: uma única Beta gratuita, sem Pro, preço, checkout, assinatura,
  anúncios ou paywall;
- core privado e Analyze/Optimize só abrem após os P0 e receipts próprios;
- enquanto toda a matriz estiver `OFF`, a Web pública permanece informativa e
  não apresenta CTA ou link para `/app`;
- Generate/Rebuild, learning, Battle, Scanner, social, marketplace e trades
  permanecem `OFF` por padrão;
- a única direção pública planejada para Battle interativo é Jogar contra IA,
  com o humano controlando mão, campo, alvos, prioridade e combate contra um
  adversário da IA; não haverá rota, CTA ou modo público de espectador, nem
  fallback para simulação/replay quando o XMage interativo estiver bloqueado;
- a prova focal Web/XMage de 2026-08-25 passou do mulligan ao replay/rematch e
  está registrada em
  `docs/qa/execution/2026-08-25/play-vs-ai-real-xmage-e2e.md`; ela valida a
  implementação contida, mas não libera Battle nem substitui clean-SHA,
  aggregate UI, Android físico, acessibilidade, capacidade ou rollout;
- baseline estrutural deste checkout: migration `058`, com `58` migrations; o
  estado do PostgreSQL live continua desconhecido até receipt read-only fresco;
- nenhum status local altera `live_verified_as_of` sem prova same-SHA fresca.

## Atualização de prioridade — 2026-08-12

O índice de execução vigente é
`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`. Ele consolida os
achados posteriores deste documento, separa blockers da beta core dos blockers
de Battle, Scanner, Social e monetização e incorpora a direção visual orientada
por imagens de cartas. As seções abaixo continuam como histórico e contexto das
decisões implementadas nas respectivas datas; não devem substituir o estado,
as dependências ou os critérios de aceite do backlog mestre.

> O corpo histórico (2026-03-23 a 2026-07-30) foi movido para `docs/archive/2026-09/CONTEXTO_PRODUTO_ATUAL_HISTORICO_2026-03-23_a_2026-07-30.md`.
>
> **Estado verificado do projeto (onde estamos e o que falta para a beta):** `docs/status/ESTADO_DO_PROJETO_2026-09-22.md`, com a evidência em `docs/verdade/FATOS.md`.
