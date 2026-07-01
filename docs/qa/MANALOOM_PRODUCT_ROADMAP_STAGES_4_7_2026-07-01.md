# ManaLoom Product Roadmap - Etapas 4 a 7

Data: 2026-07-01
Status: MVP implementado e auditado no app em 2026-07-01.

Este documento formaliza as proximas etapas de produto depois do diagnostico,
core e readiness tecnico. O fechamento tecnico anterior continua valido como
base de release; estas etapas abaixo tratam de monetizacao, diferencial,
retencao e crescimento.

## Visao executiva

| Etapa | Nome | Objetivo | Status |
|---|---|---|---|
| 4 | Produto Comercial e Monetizacao | Transformar recurso em oferta vendavel | MVP_IMPLEMENTADO |
| 5 | Diferencial Principal | Sair de "mais um deck builder com IA" | MVP_IMPLEMENTADO |
| 6 | Retencao e Uso Continuo | Fazer o usuario voltar toda semana | MVP_IMPLEMENTADO |
| 7 | Comunidade, Trade e Crescimento | Transformar usuarios em rede | MVP_IMPLEMENTADO |

## Fechamento MVP - 2026-07-01

Arquivos principais implementados:

- `app/lib/features/commercial/`: plano Free/Pro, medidor de uso de IA,
  paywall, upgrade, checkout interno e textos legais.
- `app/lib/features/retention/`: notas pos-jogo, problemas recorrentes,
  cartas que performaram bem/mal e resumo de evolucao do deck.
- `app/lib/features/growth/`: sinal de trade matching baseado em wishlist,
  cartas faltantes, duplicadas e cartas para troca.
- `app/lib/features/decks/screens/deck_generate_screen.dart`: medidor de IA e
  paywall antes da geracao.
- `app/lib/features/decks/screens/deck_details_screen.dart`: paywall antes de
  explicacao/otimizacao, rota de pos-jogo e payload de recomendacao.
- `app/lib/features/decks/widgets/deck_optimize_sections.dart`: controles de
  colecao, orcamento, intencao e bracket.
- `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart`: relatorio
  antes/depois compartilhavel e metadados de funcao, risco, curva, preco e
  bracket por sugestao quando disponiveis.
- `app/lib/features/community/screens/community_screen.dart`: painel de rede,
  fichario, want list, trades e busca de jogadores.

Validacao executada:

- `flutter test test/features/commercial/commercial_provider_test.dart test/features/retention/post_game_note_store_test.dart test/features/growth/trade_match_summary_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/widgets/deck_optimize_dialogs_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart`
- `flutter analyze`

Auditoria:

- `docs/qa/MANALOOM_STAGE4_7_MVP_IMPLEMENTATION_AUDIT_2026-07-01.md`

Limites conscientes do MVP:

- Checkout atual ativa Pro localmente para validar oferta/paywall. Producao ainda
  exige integracao real com Stripe/Mercado Pago/backend.
- Comentarios/moderacao de comunidade nao foram implementados neste corte.
- Alertas push/preco/trade automaticos ainda dependem de backend/agendador.

## Etapa 4 - Produto Comercial e Monetizacao

Objetivo: transformar recurso em oferta vendavel.

### Implementar ou definir

- Tela de plano Free/Pro.
- Medidor de uso de IA.
- Limites claros por plano.
- Paywall quando limite acabar.
- Pagina de upgrade.
- Checkout ou integracao de pagamento.
- Politica legal/IP para monetizacao.
- Texto de termos, privacidade e disclaimer.

### Entregaveis

- Modelo de planos:
  - Free: limite claro de geracoes/otimizacoes por periodo.
  - Pro: mais uso de IA, relatorios, historico avancado e recursos premium.
- `usage meter` visivel nos pontos de IA.
- Estado de limite atingido com CTA de upgrade.
- Pagina de upgrade com proposta de valor simples.
- Fluxo de checkout definido ou integrado.
- Termos, privacidade, disclaimer de IA e aviso de propriedade intelectual.

### Criterio de pronto

O usuario entende:

- o que e gratis;
- por que pagaria;
- qual limite atingiu;
- o que ganha no Pro;
- como fazer upgrade.

### Status do MVP

`MVP_IMPLEMENTADO`.

Implementado no app:

- Rotas `/plans`, `/upgrade`, `/checkout` e `/legal`.
- `CommercialProvider` com plano Free/Pro, periodo mensal e limite de IA.
- Medidor de uso de IA no gerador e no perfil.
- Paywall antes de geracao, otimizacao e explicacao de carta.
- Checkout interno para ativar Pro localmente.
- Termos, privacidade, IP, disclaimer de IA e nota de monetizacao.

Pendente para producao paga:

- Provedor de pagamento real.
- Persistencia server-side do plano e limites.
- Webhook/recibo/cancelamento/reembolso.

### Riscos

- Monetizar MTG exige revisao de Fan Content Policy/IP.
- Paywall agressivo pode reduzir aquisicao.
- Sem medidor transparente, limite de IA parece erro tecnico.

### Prioridade sugerida

Alta para release comercial. Nao bloqueia teste interno, mas bloqueia oferta
paga confiavel.

## Etapa 5 - Diferencial Principal

Objetivo: sair de "mais um deck builder com IA".

### Diferenciais priorizados

- Otimizacao por colecao: "melhore usando cartas que eu tenho".
- Otimizacao por orcamento: "melhore ate R$ 100".
- Explicacao de cada troca: funcao, risco, curva, preco e bracket.
- Relatorio antes/depois compartilhavel.
- Sugestoes por nivel da mesa/Commander Bracket.
- Rebuild guiado com intencao:
  - casual;
  - upgraded;
  - optimized;
  - cEDH.

### Entregaveis

- Filtros de otimizacao:
  - usar apenas minha colecao;
  - respeitar orcamento maximo;
  - respeitar bracket/nivel da mesa;
  - preservar tema/arquetipo.
- Explicacao estruturada por troca:
  - carta removida;
  - carta sugerida;
  - motivo;
  - impacto na curva;
  - impacto no preco;
  - impacto no bracket;
  - risco ou tradeoff.
- Relatorio antes/depois com share externo.
- Rebuild guided como fluxo proprio, nao so mensagem de erro.

### Criterio de pronto

O usuario confia na recomendacao porque entende:

- qual problema esta sendo resolvido;
- por que aquela carta entra;
- por que aquela carta sai;
- quanto custa;
- se muda o nivel da mesa;
- quais riscos a troca cria.

### Status do MVP

`MVP_IMPLEMENTADO`.

Implementado no app:

- Controles de priorizar colecao, orcamento em R$, bracket e intencao
  `casual/upgraded/optimized/cEDH`.
- Contexto enviado no payload `recommendation_context` para `/ai/optimize`.
- Preview continua obrigatorio antes de aplicar.
- Relatorio antes/depois agora e compartilhavel.
- Sugestoes exibem funcao, prioridade, risco, curva, preco, bracket e impacto
  quando estes campos vierem do backend.

Pendente para diferenciar em producao:

- Backend precisa honrar `recommendation_context` com dados reais de colecao,
  preco e disponibilidade.
- Share social com preview/link publico ainda depende do backend de deep link.

### Riscos

- Explicacao pobre reduz confianca na IA.
- Orcamento/preco precisa fonte confiavel e atualizacao.
- Colecao do usuario precisa estar facil de manter.

### Prioridade sugerida

Muito alta. Este e o diferencial que pode justificar pagamento e recorrencia.

## Etapa 6 - Retencao e Uso Continuo

Objetivo: fazer o usuario voltar toda semana.

### Ciclos a criar

- Historico de partidas.
- Notas pos-jogo.
- Cartas que performaram bem/mal.
- Problemas de mana, compra, remocao ou win condition.
- Sugestao automatica depois da partida.
- Evolucao do deck ao longo do tempo.
- Alertas de melhoria, preco e cartas faltantes.

### Entregaveis

- Registro de partida por deck:
  - resultado;
  - pod/mesa;
  - bracket percebido;
  - problemas observados;
  - cartas destaque;
  - cartas fracas.
- Analise pos-jogo:
  - diagnostico resumido;
  - recomendacao de ajuste;
  - alerta de problema recorrente.
- Linha do tempo do deck:
  - versoes;
  - mudancas;
  - motivo das mudancas;
  - desempenho percebido.
- Alertas:
  - carta ficou mais barata;
  - carta faltante apareceu em trade;
  - deck tem problema recorrente de mana/compra/remocao.

### Criterio de pronto

O ManaLoom deixa de ser usado so para montar deck e passa a acompanhar a vida do
deck.

O usuario tem motivo para voltar porque:

- registrou uma partida;
- recebeu insight pos-jogo;
- acompanha evolucao;
- ve melhorias pendentes;
- recebe alertas uteis.

### Status do MVP

`MVP_IMPLEMENTADO`.

Implementado no app:

- Rota `/decks/:id/post-game`.
- Registro local de partida por deck com resultado, nivel da mesa, notas,
  cartas boas/ruins e problemas de mana/compra/remocao/win condition.
- Resumo de evolucao com problemas recorrentes, top performers, cartas para
  revisar e sugestoes automaticas.

Pendente para retencao completa:

- Sincronizacao server-side.
- Timeline de versoes do deck ligada a mudancas aplicadas.
- Alertas automaticos de preco, carta faltante e trade.

### Riscos

- Registro pos-jogo precisa ser muito rapido; se for burocratico, nao vira habito.
- Alertas demais viram ruido.
- Historico sem insight nao cria retencao.

### Prioridade sugerida

Alta depois do diferencial principal. E o motor de recorrencia semanal.

## Etapa 7 - Comunidade, Trade e Crescimento

Objetivo: transformar usuarios em rede.

### Fortalecer

- Decks publicos com analise visual.
- Perfil de jogador.
- Seguir jogadores.
- Comentarios ou feedback em decks.
- Binder publico.
- Lista de cartas para troca.
- Match entre cartas faltantes e usuarios que tem para trade.
- Compartilhamento externo do deck/analise.

### Entregaveis

- Deck publico com:
  - resumo visual;
  - bracket;
  - curva;
  - plano de jogo;
  - pontos fortes/fracos;
  - relatorio antes/depois quando existir.
- Perfil de jogador:
  - decks publicos;
  - estilo preferido;
  - brackets;
  - colecao/trades publicos opcionais.
- Social:
  - seguir jogador;
  - feed simples de decks/alteracoes;
  - comentarios ou feedback.
- Trade:
  - binder publico;
  - wishlist/cartas faltantes;
  - match entre quem precisa e quem tem.
- Growth:
  - link compartilhavel;
  - preview social;
  - relatorio exportavel.

### Criterio de pronto

O produto deixa de ser ferramenta isolada e vira rede:

- usuarios descobrem decks;
- seguem jogadores;
- recebem feedback;
- encontram cartas para troca;
- compartilham analises fora do app.

### Status do MVP

`MVP_IMPLEMENTADO`.

Implementado no app:

- Painel de rede/trade na comunidade.
- Acoes diretas para fichario, want list, trades e busca de jogadores.
- Sinal de match usando `BinderStats`: wishlist, faltantes, cartas para troca e
  duplicadas.
- Comunidade existente preserva decks publicos, feed de seguidos, perfis,
  binder publico e rotas de trade.
- Relatorio de otimizacao pode ser compartilhado externamente.

Pendente para crescimento completo:

- Comentarios/feedback em decks com moderacao.
- Match real entre carta faltante e usuarios especificos com disponibilidade.
- Preview social/link publico para relatorios antes/depois.

### Riscos

- Moderacao e abuso em comentarios.
- Privacidade da colecao/binder precisa ser opt-in.
- Trade exige clareza de responsabilidade: o app facilita contato, nao garante transacao.

### Prioridade sugerida

Media-alta. Crescimento depende disso, mas deve vir depois de monetizacao clara e
diferencial forte.

## Ordem recomendada de execucao

1. Etapa 4: definir plano Free/Pro, medidor e paywall minimo.
2. Etapa 5: implementar otimizacao por colecao/orcamento com explicacao de troca.
3. Etapa 6: criar notas pos-jogo e timeline do deck.
4. Etapa 7: fortalecer perfil, deck publico e match de trade.

## Regras de aceite do roadmap

- Cada etapa deve ter tela, API/estado e teste/smoke correspondente.
- Cada recurso pago precisa deixar claro o valor antes do paywall.
- Qualquer dado publico de colecao/trade deve ser opt-in.
- Qualquer recomendacao de IA deve explicar motivo e tradeoff.
- Antes de monetizar, revisar Fan Content Policy/IP, termos, privacidade e disclaimer.

## Relacao com readiness tecnico

As etapas tecnicas anteriores seguem como pre-requisito para liberar comercialmente:

- Sentry mobile configurado.
- Keystore Android real.
- Signing iOS/TestFlight.
- Aceite final Android completo sem blockers de UX.

Sem esses itens, as Etapas 4-7 podem ser implementadas e testadas internamente,
mas nao devem ser usadas para venda publica.
