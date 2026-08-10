# ADR 0008 — Fronteira entre decklist e cópia física do Binder

- Status: accepted
- Date: 2026-08-05
- Scope: cards, deck cards, Binder, public deck copy, Sample Hand and Optimize

## Context

Uma linha de `deck_cards` escolhe uma impressão do catálogo por `card_id`,
quantidade e papel de comandante. O schema também preserva um campo legado de
condição. Já uma linha de `user_binder_items` representa cópias possuídas ou
desejadas e distingue impressão, condição, acabamento foil, idioma e lista.

Misturar esses dois grãos criaria afirmações que o produto não consegue
provar. Em especial, `cards.foil` vem da sincronização do catálogo e descreve
capacidade conhecida da impressão; não identifica o acabamento de uma cópia do
usuário. Quantidade alocada por identidade jogável também não informa quais
linhas físicas do Binder foram colocadas em qual deck.

Persistir `language` e `is_foil` diretamente em `deck_cards` duplicaria a
verdade física do Binder, ampliaria assinaturas e caches do Optimize e poderia
vazar preferências de coleção ao copiar ou publicar um deck. O mesmo problema
continuaria existindo para múltiplas cópias com condições e idiomas diferentes.

## Decision

1. `decks` e `deck_cards` representam a decklist: impressão escolhida,
   quantidade e papel de comandante. Não representam alocação de um item
   físico do Binder.
2. `user_binder_items` permanece a fonte PostgreSQL da identidade da cópia:
   impressão, condição, `is_foil`, idioma, quantidade e tipo de lista.
3. `cards.foil` é capacidade da impressão no catálogo. A UI usa linguagem de
   disponibilidade (`Foil disponível` ou `Sem foil`) e nunca a apresenta como
   acabamento possuído.
4. `deck_cards.condition` é compatibilidade legada da linha da decklist. Ela é
   preservada por mutations e assinaturas existentes, mas não prova vínculo
   com uma cópia do Binder.
5. Deck detail, Sample Hand, Optimize e deck público não alegam idioma nem
   acabamento físico. Uma cópia pública preserva somente estrutura e impressão
   de catálogo, nunca metadados do Binder.
6. Os agregados de disponibilidade podem comparar demanda da decklist com
   estoque por identidade jogável, mas não podem inventar uma alocação física
   individual.
7. Se o produto passar a exigir “esta cópia específica está neste deck”, a
   mudança deve usar um contrato explícito de alocação que referencie
   `deck_cards` e `user_binder_items`, distribua quantidades de forma validada e
   defina privacidade, remoção e concorrência. Não serão adicionados escalares
   duplicados à decklist como atalho.

## Consequences

- A decklist continua compartilhável sem expor idioma, condição real ou
  acabamento da coleção.
- Binder, Marketplace e Trades podem afirmar identidade física porque leem o
  item ou seu snapshot imutável.
- Optimize e Sample Hand continuam determinísticos sobre a impressão do
  catálogo e não precisam incorporar inventário físico em signatures/caches.
- O produto pode dizer quantas cópias jogáveis faltam ou estão livres, mas não
  qual cópia física está em um deck até existir o contrato de alocação.
- Nenhuma migration é necessária para esta decisão; o fechamento é de
  semântica, UI e contrato.

## Rejected alternatives

- Adicionar `language` e `is_foil` a `deck_cards`: duplica a verdade, não
  resolve múltiplas cópias e cria risco de drift e privacidade.
- Tratar `cards.foil` como acabamento da carta no deck: transforma capacidade
  do catálogo em fato físico inexistente.
- Inferir a cópia pelo estoque disponível: a mesma identidade jogável pode ter
  várias impressões, idiomas, condições e acabamentos.
- Remover imediatamente `deck_cards.condition`: quebraria compatibilidade de
  mutation, assinatura e histórico sem entregar a alocação correta.

## Review triggers

Revisar esta decisão somente se houver requisito aprovado para alocar cópias
específicas a decks, exportar metadados físicos privados ou reservar inventário
por linha. A revisão deve incluir schema, concorrência, privacidade, copy de
deck público, Optimize, Trades e migração do campo legado de condição.
