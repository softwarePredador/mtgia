# Commander Product Roadmap — 2026-03-18

## Objetivo

Consolidar em um único documento o fluxo de evolução do produto, incluindo:

- posicionamento de produto
- evolução do app
- evolução do backend de otimização
- consolidação visual de cores/layout
- qualidade, testes e gates de release

Direção principal:

- foco em `Commander-first`
- priorização do loop `montar -> otimizar -> jogar -> gerenciar coleção/trade`
- despriorização temporária de expansões horizontais que não aumentem valor para esse loop

## Posicionamento recomendado

O app já é mais forte em Commander do que em formatos 60-card.  
O melhor caminho é assumir isso explicitamente pelas próximas sprints.

Proposta:

- ser o melhor app para jogador de Commander montar, ajustar e jogar o deck

Evitar, por enquanto:

- tentar parecer igualmente profundo para Standard, Modern, Pioneer, Legacy e Vintage
- gastar sprint com features laterais antes de fechar o núcleo

## Escopo incluído no roadmap

Este roadmap cobre todas as frentes que já foram discutidas e validadas:

- fluxo de deck
- optimize / rebuild / safe-no-change
- playtest leve
- contador de vida
- coleção / marketplace / trades
- identidade visual, cores e layout
- validação e gate de release

## Núcleo que deve ser preservado

- criação de deck
- importação de deck
- geração de deck por IA
- otimização de deck
- rebuild guiado quando o deck está ruim
- coleção + marketplace + trades

## Documentos complementares

- produto e visual:
  - `app/doc/COMMANDER_PRODUCT_ROADMAP_2026-03-18.md`
  - `app/doc/COMMANDER_EXECUTION_TRACKER_2026-03-18.md`
  - `app/doc/DESIGN_COLOR_LAYOUT_AUDIT_2026-03-18.md`
  - `app/doc/LIFE_COUNTER_TABLETOP_UX_HANDOFF_2026-03-18.md`
- otimização e validação:
  - `server/doc/OPTIMIZATION_RESOLUTION_HANDOFF_2026-03-18.md`
  - `server/doc/RESOLUTION_CORPUS_WORKFLOW.md`

## Fluxo mestre de execução

O caminho recomendado não é evoluir tudo ao mesmo tempo.  
É seguir a sequência abaixo:

1. estabilizar base e gates
2. fortalecer o loop de decks
3. consolidar identidade visual
4. elevar o contador de vida
5. conectar deck, coleção e trade
6. instrumentar produção e usar isso como gate real de evolução

## Roadmap consolidado

### Fase 0 — Fundação e gates

Objetivo:

- garantir que o produto evolua sobre base estável
- evitar regressão de optimize, layout e UX

#### Must-have

- manter o gate de resolução fim a fim estável
- expandir corpus de otimização de `10` para `15-20` decks reais
- usar o runner de resolução como referência principal de qualidade
- manter `flutter analyze` e `flutter test` verdes
- manter cobertura de overflow nas telas mais sensíveis

#### Should-have

- ampliar testes de overflow para mais áreas críticas
- criar baseline visual por módulo principal

#### Dependências

- `server/test/fixtures/optimization_resolution_corpus.json`
- `server/test/artifacts/optimization_resolution_suite/latest_summary.json`
- `app/test/features/**`

#### Impacto esperado

- reduzir risco de regressão
- dar previsibilidade para as próximas fases

### Fase 1 — Decks como carro-chefe

#### Must-have

- painel de diagnóstico do deck
  - terrenos
  - ramp
  - draw
  - remoções
  - wipes
  - curva
  - CMC
  - cores
- otimização mais clara
  - o que sai
  - o que entra
  - por que mudou
  - impacto esperado
- estados de resultado bem distintos
  - `optimized`
  - `safe_no_change`
  - `rebuild_guided`
- feedback de progresso durante optimize / rebuild
  - etapa atual
  - progresso compreensível
  - dicas úteis enquanto o servidor processa
- playtest leve
  - mão inicial
  - mulligan
  - sample hand
  - goldfish simples

#### Should-have

- alternativas por slot
- histórico de otimizações por deck

#### Nice-to-have

- comparação entre versões do deck

#### Impacto esperado

- aumentar valor percebido para brewer de Commander
- fazer o usuário confiar mais na IA

#### Progresso já executado em 2026-03-18

- painel de diagnóstico rápido na visão geral do deck com:
  - terrenos
  - ramp
  - compra
  - interação
  - wipes
  - CMC médio
  - leitura rápida do estado da lista
- playtest leve trazido para o fluxo principal com:
  - sample hand compacta na visão geral do deck
  - mulligan direto no mesmo componente
  - leitura rápida de keep / mão arriscada
  - comandante removido do pool da mão inicial em Commander
- estados secundários de deck refinados com:
  - loading de salvamento mais coerente no `deck_generate`
  - resultado de importação mais legível no `deck_import`
  - descrição e explicação de carta com dialogs mais alinhados ao fluxo principal
- preview de otimização mais claro e menos “painel técnico”
- loadings de optimize e rebuild com:
  - etapa humanizada
  - barra de progresso
  - dicas rotativas úteis

### Fase 2 — Consolidação visual, cores e layout

Objetivo:

- fechar a identidade visual do app
- remover sensação de “módulos de maturidade diferente”

#### Progresso já executado em 2026-03-18

- remoção da duplicidade estrutural do shell principal
- correção de overflows críticos em marketplace, social, onboarding e trades
- criação de testes de overflow para telas sensíveis
- consolidação visual parcial em:
  - `auth`
  - `home`
  - `notifications`
  - `latest set`
  - `life counter`
- ampliação do `AppTheme` para feedback visual mais consistente
- centralização dos hardcodes mais visíveis de cor nos módulos de maior percepção
- centralização de semântica MTG no `AppTheme`
  - raridade
  - fallback de pips / símbolos de mana
- consolidação visual aplicada em:
  - `card_detail`
  - `deck_card`
  - header principal de `deck_details`
- unificação inicial de estados vazios/erro com componente compartilhado em:
  - notifications
  - messages
  - trade inbox
  - latest set collection

#### O que ainda resta nesta fase

- reduzir hardcodes restantes em estados secundários de `deck_details`
- revisar contraste fino e hierarquia visual das sheets de deck
- consolidar estados vazios e headers secundários em mais módulos

#### Must-have

- reduzir hardcoded colors fora de `AppTheme`
- consolidar componentes visuais principais:
  - app bars
  - section headers
  - summary cards
  - empty states
  - badges / chips
- equalizar a qualidade visual de:
  - onboarding
  - latest set
  - trades
  - contador de vida

#### Should-have

- revisar contraste e legibilidade em telas utilitárias
- padronizar melhor hero sections e blocos de conteúdo

#### Nice-to-have

- motion mais consistente
- melhor acabamento visual em estados vazios e telas secundárias

#### Impacto esperado

- aumentar percepção de qualidade
- deixar o app mais coeso visualmente

### Fase 3 — Contador de vida realmente útil

#### Ergonomia de mesa já registrada

Referência operacional:

- `app/doc/LIFE_COUNTER_TABLETOP_UX_HANDOFF_2026-03-18.md`

Pontos obrigatórios para esta fase:

- zona neutra de controle para ações críticas
- alvos de toque confortáveis
- ausência de chrome desnecessário durante partida
- leitura mais natural para múltiplos lados da mesa

#### Progresso já executado em 2026-03-18

- hub central de mesa para `config`, `undo` e `reset`
- rotação melhor dos painéis superiores no multiplayer
- alvos de toque ampliados
- `commander casts` e `commander tax` integrados ao contador
- persistência da sessão atual
- atalhos rápidos de `+5/-5`
- `Storm`, `Monarch` e `Initiative` integrados ao hub de mesa
- `coin flip`, `d20` e sorteio do primeiro jogador no fluxo da partida

#### Must-have

- consolidar a ergonomia final dos controles de mesa
- revisar suporte a casos específicos de Commander
  - `Partner`
  - múltiplos comandantes
- validar presets de mesa por formato sem poluir a UX principal

#### Should-have

- suporte melhor para `Partner` / múltiplos comandantes
- presets de mesa para Commander multiplayer

#### Nice-to-have

- temas visuais de mesa

#### Impacto esperado

- aumentar frequência de uso
- transformar o contador em motivo real para abrir o app durante partidas

### Fase 4 — Coleção e trade conectados ao deck

#### Must-have

- mostrar no deck:
  - cartas que o usuário já possui
  - cartas faltantes
  - cartas disponíveis para compra/troca
- matching entre `have` e `want`
- fluxo rápido de proposta de trade a partir do deck
- filtros melhores de coleção

#### Should-have

- sugestão de trade “justo” por valor
- alerta quando carta desejada aparecer disponível

#### Nice-to-have

- watchlist de staples / comandantes

#### Impacto esperado

- aumentar retenção
- diferenciar o app de deckbuilders puros

### Fase 5 — Produção, métricas e release gate

Objetivo:

- medir valor real do produto em uso
- transformar a evolução em processo repetível

#### Must-have

- instrumentar produção para:
  - `% optimized_directly`
  - `% rebuild_guided`
  - `% safe_no_change`
  - `% usuários que usam contador`
  - `% usuários que conectam deck + binder`
- usar a suíte de resolução como gate antes de release
- manter documentação de handoff atualizada a cada marco importante

#### Should-have

- medir retenção por módulo
- medir adoção do playtest e do trade

#### Impacto esperado

- validar produto com dado real
- impedir regressão silenciosa

## Ordem técnica recomendada

### Ordem exata

1. manter foundation e gates verdes
2. diagnóstico visual do deck
3. revisão da UX de optimize
4. playtest leve
5. limpeza de hardcoded colors e padronização visual
6. refinamento de onboarding / latest set / trades
7. contador de vida base
8. contador Commander completo
9. deck ↔ binder
10. matching/trade
11. métricas e gate de release

### O que pode rodar em paralelo

- expansão do corpus de otimização
- limpeza visual de cor/layout
- evolução do contador de vida

### O que não deve correr em paralelo sem base pronta

- expansão forte de trade/marketplace antes de deck e contador estarem fortes
- expansão de formatos 60-card antes de Commander ficar realmente sólido

## Backlog executivo

### P0

- foundation e gate de qualidade
- diagnóstico do deck
- otimização mais clara
- rebuild/safe-no-change bem explicados
- playtest leve
- limpeza de hardcoded colors mais críticas
- equalização visual dos módulos mais fracos
- contador de vida com recursos básicos de Commander

### P1

- consolidação visual completa
- deck ↔ binder
- matching de coleção/trade
- alternativas de otimização
- histórico de versões
- contador de vida Commander completo

### P2

- social extra
- market movers
- refinamentos cosméticos não ligados ao núcleo
- expansão forte para formatos não-Commander

## KPIs sugeridos

- `% de decks que chegam até otimização`
- `% de usuários que aplicam sugestão`
- `% de fluxos que terminam em resultado útil`
- `% de sessões que usam contador de vida`
- `% de decks com playtest executado`
- `% de usuários que conectam deck + binder`
- `% de trades iniciados a partir de deck/coleção`
- `% de sessões que entram em rebuild_guided`

## Critério de sucesso

Ao fim desse ciclo, o app precisa entregar 3 promessas claramente:

1. montar e ajustar deck melhor
2. usar na mesa sem precisar de outro contador
3. ligar deck, coleção e trade no mesmo fluxo

Além disso, precisa manter:

4. consistência visual suficiente para parecer um produto único
5. gates de qualidade estáveis antes de cada release

## Arquivos centrais para começar a execução

### Produto / App

- `app/lib/features/decks/screens/deck_details_screen.dart`
- `app/lib/features/decks/screens/deck_generate_screen.dart`
- `app/lib/features/decks/screens/deck_import_screen.dart`
- `app/lib/features/home/life_counter_screen.dart`
- `app/lib/features/collection/screens/collection_screen.dart`
- `app/lib/features/binder/screens/marketplace_screen.dart`
- `app/lib/features/trades/screens/create_trade_screen.dart`
- `app/lib/core/theme/app_theme.dart`
- `app/lib/features/home/home_screen.dart`
- `app/lib/features/home/onboarding_core_flow_screen.dart`
- `app/lib/features/collection/screens/latest_set_collection_screen.dart`

### Backend / Qualidade

- `server/routes/ai/optimize/index.dart`
- `server/routes/ai/rebuild/index.dart`
- `server/lib/ai/rebuild_guided_service.dart`
- `server/test/fixtures/optimization_resolution_corpus.json`
- `server/bin/run_three_commander_resolution_validation.dart`

## Resumo final

Este roadmap passa a ser o fluxo mestre do produto:

1. estabilizar
2. aprofundar decks
3. consolidar visual
4. elevar contador
5. conectar coleção/trade
6. medir e travar qualidade

Se houver disputa de prioridade entre frentes, a regra é:

- priorizar o que aumenta valor para jogador de Commander
- depois priorizar o que aumenta uso recorrente
- depois priorizar o que aumenta retenção e diferenciação
