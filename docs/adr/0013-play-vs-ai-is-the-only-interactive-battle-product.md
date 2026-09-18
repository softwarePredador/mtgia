# ADR 0013 — Play vs AI é o único produto Battle interativo

- Estado: aceito para implementação contida
- Data: 2026-08-25
- Release: `NO_GO`, capabilities Battle permanecem `OFF`
- Substitui: ADR 0005 somente quanto ao nome, à experiência e à superfície
  pública; seus limites de privacidade, persistência, autenticação e resposta
  tipada continuam válidos.

## Contexto

O protótipo chamado Battle Coach já conecta um participante humano ao XMage,
mantém a mão própria privada e recebe respostas tipadas para os callbacks
interativos. A experiência, porém, apresentava o motor como condutor da partida
e as decisões do usuário como pausas ocasionais. Em paralelo, Battle Live
expunha uma visão read-only de espectador.

Essa combinação não representa o produto escolhido. O valor para o usuário é
jogar Magic contra uma IA, vendo e controlando o próprio lado da mesa. Uma
visão de espectador não faz parte da proposta pública.

## Decisão

1. O único produto Battle interativo para o usuário é **Jogar contra IA**: um
   humano controla o próprio deck e uma IA controla um único adversário.
2. A rota canônica é `/decks/:id/play-vs-ai[/sessionId]`. As rotas históricas
   `/battle-coach` podem existir temporariamente apenas como redirect de
   compatibilidade e nunca aparecem em navegação, CTA, inventário público ou
   comunicação do produto.
3. Não existe rota, CTA ou modo público de espectador. O stream Live, seus
   checkpoints e os replays podem continuar como transporte, recuperação,
   observabilidade e evidência internos da partida.
4. A mesa é card-first: adversário/status no topo, campo e pilha no centro,
   mão própria sempre visível na base e ações legais em uma bandeja contextual
   que não encobre o tabuleiro.
5. Quando uma opção legal referencia uma carta visível, a própria carta é a
   ação primária. O painel textual permanece como alternativa acessível e para
   respostas sem carta, valores inteiros e distribuições.
6. O motor aplica regras, avança fases e executa o adversário. O usuário escolhe
   suas ações legais — mulligan, mana, mágicas, alvos, prioridade/passe e
   combate — pelos prompts tipados. Delegar uma ação é opcional e vale apenas
   para o prompt corrente.
7. Nenhuma conclusão funcional é aceita somente por fixture, mock, golden ou
   widget test. A prova definitiva exige ao menos uma partida real completa no
   XMage, do mulligan ao resultado terminal, com retorno esperado validado.
8. Reconexão, idempotência, concessão, timeout honesto, replay e rematch fazem
   parte do aceite do produto; erro operacional nunca vira vitória, empate ou
   replay fabricado.
9. Cobertura interativa incompleta bloqueia **Jogar contra IA** de forma
   explícita. O fluxo nunca consulta Forge, inicia simulação automática nem
   redireciona o usuário para assistir a um replay como substituto da partida.
   Simulações permanecem isoladas no Battle Lab.
10. A capability técnica `battle_coach` pode permanecer como identificador de
   compatibilidade nesta etapa. Renomeá-la exige migration de policy/receipts e
   não é necessário para corrigir a experiência pública.
11. Esta decisão não liga capability, não autoriza deploy, migration, DML live,
    alteração de pin ou promoção de Battle. O programa horizontal e seus gates
    continuam obrigatórios antes de qualquer coorte.

## Consequências

- Battle Live deixa de ser superfície de usuário, mas seu código pode ser
  preservado enquanto houver consumidores internos auditados.
- O antigo Battle Coach passa a ser uma implementação técnica legada atrás da
  experiência Play vs AI; textos e rotas públicas deixam de usar “Coach”.
- A UI precisa provar que mão e ações permanecem alcançáveis em `390x844`,
  `844x390` e `1440x900`, incluindo teclado Web e semântica móvel.
- O gate real de partida precisa cobrir a mesma versão de app/backend/sidecar e
  registrar pin, SHA, callbacks exercitados, estado terminal e divergências.

## Evidência esperada

- `BT-PLAY-001`: mesa card-first e ausência de espectador público.
- `BT-PLAY-002`: partida XMage completa e validação dos casos de uso.
- `BT-PLAY-003`: resiliência, acessibilidade, capacidade e rollout controlado.

## Evidência focal obtida em 2026-08-25

O runner `scripts/manaloom_play_vs_ai_e2e.sh`, com browser QA habilitado,
concluiu uma partida real contida no XMage pinado. A mesma sessão Web exercitou
seleção de oponente, target inicial, mulligan, land drop, mana, cast de Isamaru,
prioridade, combate com dano, reload/reconexão, concessão, replay e rematch. O
relatório final cruzou API, 232 registros PostgreSQL, replay canônico e nove
capturas Web revisadas; cleanup passou sem kill forçado.

O receipt está em
`docs/qa/execution/2026-08-25/play-vs-ai-real-xmage-e2e.md`. Esta evidência
confirma a direção técnica e visual, mas não fecha antecipadamente
`BT-PLAY-001/002`, porque o slot `NOW`, o clean-SHA, os P0 Battle e os gates de
rollout continuam regidos pelo backlog. Capabilities permanecem `OFF` e o
estado de release continua `NO_GO`.
