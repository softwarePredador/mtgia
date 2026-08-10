# ManaLoom — implementação do polish responsivo P1

Data: 2026-08-06
Digest UI: `df8c3371454fad3b57b6fdf5e6a9a8bcce76d43f90dc9fdaf784759ac44eb966`
Estado: `IMPLEMENTATION_COMPLETE_LOCAL · AUTOMATED_FULL_PASS · FOCAL_WEB_VISUAL_PASS · GLOBAL_REANCHOR_INCOMPLETE`

## Resultado

As duas dívidas P1 abertas pela auditoria integral foram implementadas no
checkout local:

1. o detalhe de deck não comprime mais `Visão Geral` para `Visão Ge` em
   390×844; as quatro abas preservam o rótulo integral e usam rolagem
   horizontal deliberada somente no breakpoint compacto;
2. estados vazios/erro/offline/indisponível e o resultado único de Trade agora
   recompõem o canvas desktop/wide como workspace, sem transformar uma coluna
   mobile em um card estreito ampliado.

O patch não altera rotas, APIs, schema, pins, regra de carta, deck, runtime ou
deploy. Nenhuma escrita foi executada em PostgreSQL, Hermes ou SQLite.

## Implementação

### Abas do detalhe de deck

`app/lib/features/decks/screens/deck_details_screen.dart` passou a medir a
largura local do `TabBar`:

- abaixo do breakpoint compacto: `isScrollable`, alinhamento inicial, padding
  lateral reduzido e rótulos completos;
- nos demais breakpoints: distribuição preenchida preservada;
- anchors estáveis foram adicionados ao `TabBar` e às quatro abas.

O teste em 390×844 verifica que `Visão Geral` existe integralmente, permanece
dentro do viewport e que `Visão Ge` não é renderizado.

### Estados com pouco conteúdo

`app/lib/core/widgets/app_state_panel.dart` agora diferencia a composição por
largura:

- mobile: visual, eyebrow, título, explicação e ação em coluna compacta;
- largura intermediária: visual e conteúdo lado a lado;
- desktop/wide: rail visual de 240 px, divisor e workspace de texto limitado a
  620 px dentro de uma faixa de até 1080 px.

A solução amplia hierarquia e densidade sem inventar métricas, cards ou
decoração que não ajudem a próxima ação.

### Match único de Trade

`app/lib/features/trades/screens/trade_matches_screen.dart` mantém o card
empilhado e com largura útil completa no mobile. Em 1040 px ou mais, um único
resultado usa mestre–detalhe: contexto e privacidade à esquerda; impressão,
disponibilidade, jogador, preço e CTA em uma área de tarefa ampla à direita.
Listas com vários resultados continuam empilhadas.

### Correções contratuais encontradas pelos gates

A repetição da suíte completa encontrou quatro dívidas do checkout amplo e
elas foram fechadas sem mudar dados ou contratos externos:

- falhas genéricas de Mensagens, Decks, Comunidade e conexões de perfil não
  usam mais `AppStateStatus.offline`; o app só afirma “sem conexão” quando há
  sinal explícito, e os demais casos usam o estado honesto de erro;
- as larguras de 320 px dos rails de identidade e de 148 px do campo compacto
  passaram a tokens canônicos de `AppTheme`, sem alterar a geometria;
- retries de pós-jogo e busca de jogadores ganharam keys estáveis; os testes
  deixaram de depender da classe visual antiga do botão;
- uma asserção server-side antiga foi alinhada ao contrato público vigente de
  Battle Live, que permite a identidade exata de permanentes públicos. Foi uma
  correção somente de teste, sem ampliar payload ou comportamento do servidor.

## Verificação executada

- analyzer focal de 18 arquivos de source/test: sem issues;
- sete arquivos de testes focais, incluindo guards de offline e spacing:
  `37/37 PASS`;
- suíte Flutter completa: `1525 PASS + 1 skip governado`, zero falhas;
- `quality_gate.sh full` com Node 26 já instalado: backend, Flutter, site
  público, dependency audit, smoke HTTP e harnesses locais em `PASS`;
- `ui-audit`: analyzer limpo e `56/56 PASS` antes do `ui-proof` fail-closed;
- project logic: `8/8` artefatos regenerados e sincronizados;
- regressão mobile de Trade: CTA com mais de 300 px e metadados legíveis;
- regressão wide de Trade: contexto à esquerda e card com mais de 700 px;
- regressão wide de `AppStatePanel`: workbench com pelo menos 1000 px e rail
  anterior ao conteúdo;
- Battle Live e UX-PACKs 02–08 recapturados no digest atual: `22/22` manifests
  e `239/239` PNGs em `PASS_RUNTIME`.

Foram abertas 21 capturas no digest final, sempre nos três breakpoints:

- `visual_system_07_no_results`, `08_offline` e `09_unavailable`: `9/9`;
- `social_trade_00_matches_populated`: `3/3`;
- perfil público e segurança do perfil: `6/6`;
- superfície responsiva complementar do Deck Workshop: `3/3`.

Não há overflow, campo estreito, quebra destrutiva, perda de CTA ou aparência
de card mobile comprimido nesses 21 checkpoints. Essa revisão focal não é
relabelada como aprovação global.

## Estado da evidência global

O aggregate `docs/qa/ui-live/latest.json` continua ligado ao digest anterior
`f45f96e3…` e está corretamente **stale** após a mudança app-facing. Os quatro
manifests da matriz P0 — Web mobile, desktop, wide e Samsung físico — ainda
somam `214` capturas no digest anterior.

A recaptura P0 exige iniciar a fixture autenticada, que escreve somente em um
PostgreSQL loopback descartável. Como a atividade atual proíbe escrita em
PostgreSQL, a fixture não foi iniciada. Consequentemente:

- nenhum hash antigo foi promovido para o digest novo;
- `PASS_VISUAL_REVIEWED` global não foi declarado;
- `ui-proof` deve continuar fail-closed até uma futura execução explicitamente
  autorizada da matriz P0 e a abertura integral do aggregate novo.

## Backlog após o P1

Prioridade recomendada, sem ampliar automaticamente o escopo:

1. **P2 — affordance de carrosséis mobile:** comunicar rolagem em cartas,
   printings e evidências sem depender apenas do próximo item cortado;
2. **P2 — nomes longos no Profile:** normalizar wrap/ellipsis preservando o
   nome acessível;
3. **P2 — qualidade das fixtures:** substituir texto artificial em Battle
   Learning e capturar o seletor de comandante com o CTA pai;
4. **P2/governança — Legal/Privacy:** melhorar composição de conteúdo curto e
   obter revisão jurídica externa;
5. **release separado:** TalkBack humano, teclado Web de hardware e smoke no
   Samsung, sem transferir crédito da automação.

## Limites

Não houve commit, push, migration, deploy, alteração de pins, promoção de
deck/regra, escrita live ou limpeza do checkout sujo preexistente.
