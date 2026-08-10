# ADR 0009 — Navegação, contexto e contraproposta social/trade

- Status: accepted
- Date: 2026-08-06
- Scope: Marketplace, Cotações, faltantes, fichários públicos, propostas,
  contrapropostas e comentários de decks públicos

## Context

O produto possuía dois conceitos chamados informalmente de mercado. A rota
`/market` levava a cotações agregadas, enquanto ofertas reais de jogadores
ficavam em uma aba da Coleção. Deep links de proposta preservavam apenas o
destinatário na URL; carta, tipo e origem podiam existir somente no objeto
efêmero de navegação. Um reload, compartilhamento ou abertura em nova aba
apagava justamente o contexto que motivou a negociação.

Matches de cartas faltantes também eram informativos. Eles não carregavam uma
cópia física pública verificável até a proposta. Comentários de decks públicos
eram sempre deck-level, mesmo quando a pessoa queria discutir uma carta. Por
fim, a ação de contrapropor não tinha uma transição atômica definida para
liberar as reservas da proposta anterior e revalidar as novas cópias.

## Decision

1. O destino canônico de ofertas entre jogadores é
   `/collection?tab=1`. `/marketplace` é um alias semântico para esse destino.
2. Cotações agregadas permanecem em `/community?tab=3`. `/quotes` é o alias
   semântico e `/market` é mantido somente como alias legado de Cotações.
3. Matches acionáveis vivem em `/collection/matches`, com `deck` opcional na
   query string.
4. Uma proposta recuperável usa
   `/trades/create/:receiverId?item=&type=&source=&deck=&counter=`. O objeto
   `extra` pode acelerar a primeira renderização, mas nunca é a única fonte de
   identidade crítica.
5. `item` identifica uma linha pública exata de `user_binder_items`; o backend
   revalida visibilidade, bloqueio, política de interação, impressão e
   quantidade disponível. `COALESCE(oracle_id, id)` é usado somente para
   comparar identidade jogável entre uma falta e possíveis impressões.
6. Preço, set, collector number, acabamento, idioma, condição, quantidade e
   freshness vêm da oferta/cópia física pública. Nenhuma localização privada é
   mostrada; localização só aparece quando o próprio jogador a tornou pública.
7. Comentário contextual reutiliza `deck_comments.body` no formato textual
   compatível `[Contexto: <rótulo>] <comentário>`. O app limita e sanitiza o
   rótulo, interpreta registros novos e continua lendo comentários legados.
8. Contraproposta automática é aceita somente para proposta `trade` pura,
   pendente e recebida pela pessoa autenticada. Dentro de uma única transação,
   o servidor bloqueia a original, marca-a como recusada para liberar reservas,
   revalida as cópias canônicas e cria a nova proposta, snapshots, histórico e
   mensagem. Qualquer falha desfaz toda a operação.
9. Compra e negociação mista continuam sem contraproposta automática até haver
   contrato explícito para pagamento. O ManaLoom registra proposta e conversa,
   mas não recebe, guarda nem protege pagamentos.

## Consequences

- Reload, compartilhamento e abertura em nova aba preservam destinatário,
  cópia, tipo e origem da proposta.
- Marketplace e Cotações deixam de competir pelo mesmo nome ou rota.
- Uma carta faltante pode chegar a uma oferta verificável e a uma proposta sem
  inferir impressão ou disponibilidade.
- A proposta original e a contraproposta não mantêm reservas concorrentes.
- Comentários ganham contexto legível sem migration e sem quebrar clientes ou
  registros existentes.
- PostgreSQL/backend permanece a verdade; URL e estado do app são intenção e
  cache, nunca autorização para negociar uma cópia.

## Rejected alternatives

- Usar apenas `extra` do GoRouter: não sobrevive a reload/share.
- Tornar `/market` o Marketplace agora: quebraria links existentes de Cotações
  e manteria ambiguidade sem aliases explícitos.
- Escolher a primeira impressão de um Oracle ID: pode negociar a cópia errada.
- Criar uma nova tabela apenas para contexto de comentário: adicionaria
  migration sem necessidade para o contrato de rótulo limitado desta fase.
- Criar a contraproposta e recusar a original em chamadas separadas: abre uma
  janela com duas reservas ou uma proposta nova sem encerramento da anterior.

## Review triggers

Revisar esta decisão se o produto passar a intermediar pagamento/entrega,
precisar de threads estruturadas por trecho/diff, expuser localização privada,
ou permitir contraproposta financeira. Essas mudanças exigem novos contratos
de autorização, privacidade, concorrência, retenção e release.
