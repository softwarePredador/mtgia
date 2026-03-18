# Life Counter Tabletop UX Handoff — 2026-03-18

## Objetivo

Registrar a direção de UX do contador de vida como interface de mesa, e não só como tela funcional.

Este documento serve para:

- guiar próximas melhorias do contador
- evitar regressão de ergonomia
- reaplicar os mesmos critérios em outras telas com interação intensa

## Problemas identificados antes do ajuste

- dependência excessiva do topo da tela para ações críticas
- configurações presas ao `AppBar`
- `undo` e `reset` fora da zona neutra da mesa
- alvo de toque pequeno para contadores auxiliares
- orientação pouco amigável para partidas multiplayer
- presença de ações globais irrelevantes durante a partida

## O que foi ajustado nesta rodada

- remoção das ações críticas do `AppBar`
- remoção de ações globais extras da tela de partida
- criação de um hub central de mesa com:
  - configurações
  - `undo`
  - `reset`
- aumento dos alvos de toque dos botões auxiliares
- ampliação dos botões `+/-` dentro do sheet de contadores
- rotação dos painéis superiores no modo multiplayer para leitura mais natural na mesa
- persistência da sessão atual da partida
- `commander casts` e `commander tax` integrados ao fluxo do contador
- atalhos rápidos de `+5/-5` nos painéis de vida
- `Storm`, `Monarch` e `Initiative` integrados ao fluxo da mesa
- utilidades de mesa no hub central:
  - `coin flip`
  - `d20`
  - sorteio / marcação do primeiro jogador

## Rodada visual autoral posterior

Para evitar que o contador ficasse com cara de referência copiada, a direção visual foi puxada para uma identidade própria do app:

- remoção do `AppBar` da tela principal de mesa
- criação de um medalhão central expansível em vez de barra fixa genérica
- uso de gradientes e brilho compatíveis com a paleta do `ManaLoom`
- quadrantes dos jogadores tratados como áreas de mesa imersivas, não cards escuros empilhados
- saída da tela deslocada para uma ação periférica discreta

Princípio adicional adotado:

7. Inspiração de mesa é válida; cópia literal não.
- referências externas podem orientar ergonomia
- a solução final precisa manter linguagem visual e semântica próprias do produto

## Princípios de UX de mesa adotados

1. Ações críticas devem viver em zona neutra.
- se qualquer pessoa na mesa pode precisar tocar, o controle não deve depender de uma borda específica

2. Telas de partida não devem carregar chrome desnecessário.
- ações de mensagens, notificações e navegação paralela distraem e aumentam toque acidental

3. Alvo mínimo de toque deve ser generoso.
- evitar controles abaixo de `44x44`
- em contexto de jogo, preferir ainda maior

4. O fluxo principal deve exigir o menor número de toques possível.
- alterar vida precisa ser rápido
- abrir contadores não pode parecer ação escondida

5. Orientação precisa respeitar o contexto compartilhado.
- quando a tela fica no centro da mesa, controles e leitura não podem assumir um único “lado correto”

6. Informação crítica deve ser legível à distância.
- vida e estado letal têm prioridade
- cor ajuda, mas não pode ser o único sinal

## O que ainda falta no contador

### Prioridade alta

Já entregue nesta fase:

- atalhos de `+5/-5`
- `commander tax`
- `commander casts`
- persistência da partida atual
- `Monarch`
- `Initiative`
- `Storm`
- `coin flip`
- dado / sorteio do primeiro jogador
- registro do primeiro jogador

Ainda falta:

- consolidar presets por formato dentro da experiência da mesa
- validar se `Partner` / múltiplos comandantes precisam de suporte dedicado

### Prioridade média

- presets por formato
- temas de mesa

### Prioridade baixa

- suporte mais rico para `Partner` / múltiplos comandantes

## Checklist para reaplicar em outras telas

Este checklist deve ser usado em qualquer tela com alta frequência de toque.

### Ergonomia

- ações principais ficam na região mais fácil de alcançar?
- há dependência desnecessária do topo da tela?
- os alvos de toque têm tamanho confortável?
- existe risco claro de toque acidental?

### Hierarquia

- a ação principal está visualmente clara?
- ações secundárias competem demais com a principal?
- existem elementos globais aparecendo sem ajudar a tarefa atual?

### Contexto

- a tela assume um único usuário ou é usada em contexto compartilhado?
- a orientação visual faz sentido para o modo de uso real?
- a informação importante é legível sem esforço?

## Telas que merecem essa mesma revisão

- `app/lib/features/decks/screens/deck_details_screen.dart`
- `app/lib/features/trades/screens/trade_detail_screen.dart`
- `app/lib/features/trades/screens/create_trade_screen.dart`
- `app/lib/features/decks/screens/deck_generate_screen.dart`
- `app/lib/features/decks/screens/deck_import_screen.dart`

## Critério de sucesso

O contador deve parecer:

- rápido de operar
- natural de usar no centro da mesa
- seguro contra toques errados
- forte o bastante para o jogador não abrir outro app durante a partida
