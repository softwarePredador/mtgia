# Auditoria de Ruído Visual e Uso de Cores

> Auditoria estática do app Flutter em `2026-03-25`.
> Escopo: `app/lib/features/**`, `app/lib/core/widgets/**` e tema global.

## Resumo executivo

O projeto tem uma base de tema boa em `app/lib/core/theme/app_theme.dart`, mas a disciplina de uso das cores não está uniforme entre as telas.

O problema principal não é a paleta em si. O problema é o excesso de concorrência visual entre:

- acentos primários
- semânticas (`success`, `warning`, `error`)
- cores contextuais de domínio (WUBRG, raridade, condição)
- gradientes
- overlays por alpha
- uso misto de `AppTheme.*` e `Theme.of(context).colorScheme.*`

Diagnóstico final:

- base do design system: boa
- coerência de aplicação: média
- risco de poluição visual: real em várias telas
- pior caso atual para UX: telas do core de deck em estado vazio/inicial e telas com muitos CTAs coloridos no mesmo viewport

## Fila executável da auditoria

Ordem de execução funcional por tela:

1. `app/lib/features/decks/screens/deck_details_screen.dart` - `DONE`
2. `app/lib/features/decks/screens/deck_import_screen.dart` - `DONE`
3. `app/lib/features/home/home_screen.dart` - `DONE`
4. `app/lib/features/auth/screens/login_screen.dart` - `DONE`
5. `app/lib/features/auth/screens/register_screen.dart` - `DONE`
6. `app/lib/features/auth/screens/splash_screen.dart` - `DONE`
7. `app/lib/features/scanner/widgets/scanned_card_preview.dart` - `DONE`
8. `app/lib/features/community/screens/community_screen.dart` - `BACKLOG`
9. `app/lib/features/home/life_counter_screen.dart` - `BACKLOG`

Regra aplicada nas execuções já feitas:

- reduzir concorrência entre `primary`, `secondary`, `error`, `warning` e cores contextuais
- separar estado inicial/incompleto de estado de falha
- manter só `1` CTA realmente dominante por viewport
- empurrar ações secundárias para superfícies neutras
- quando houver comandante, usar a arte como assinatura visual de baixa intensidade, não como layer dominante

## Metodologia

Foi feita varredura estática sobre:

- `AppTheme.*`
- `Colors.*`
- `Color(...)`
- `colorScheme.*`
- gradientes
- uso de alpha (`withValues(alpha: ...)`, `withOpacity(...)`)

Além disso, foi feita leitura qualitativa das telas com maior densidade de cor.

## Orçamento de cor recomendado

Regra de produto recomendada por tela:

1. no máximo `1` acento principal por viewport
2. `warning` e `error` só quando houver problema real
3. WUBRG, raridade e condição só quando adicionarem informação funcional
4. gradiente só em:
   - hero
   - CTA principal
   - splash/onboarding
5. `colorScheme.primary/secondary/error` não deve competir com `AppTheme.*` sem regra clara

## Achados estruturais

### 1. Excesso de fontes de cor

Hoje o app mistura com frequência:

- `AppTheme.*`
- `theme.colorScheme.*`
- `Colors.*`
- `Color(0x...)`

Impacto:

- intenção visual menos previsível
- mesma semântica visual com cores ligeiramente diferentes
- dificuldade de refino global

### 2. Semântica agressiva cedo demais

O core de deck ainda usa vermelho e blocos de alerta em momentos em que o usuário está só começando.

Impacto:

- deck vazio parece deck quebrado
- sensação de falha antes da construção começar
- onboarding de deck transmite punição em vez de progressão

### 3. Alpha stacking demais

Há muitas superfícies com:

- cor base
- borda com alpha
- background com alpha
- ícone com alpha
- glow/sombra com alpha

Impacto:

- ruído sutil acumulado
- telas mais “nervosas” do que sofisticadas
- menor clareza hierárquica

### 4. Cores contextuais virando decoração

Cores de:

- formato
- condição
- raridade
- WUBRG
- score

às vezes aparecem juntas no mesmo fluxo.

Impacto:

- perda de foco
- informação importante competindo com informação auxiliar

## Telas com maior risco de ruído visual

## Prioridade P0

### `app/lib/features/decks/screens/deck_details_screen.dart`

Problema:

- mistura estados de construção, validação, erro, aviso e ação
- usa vermelho em momentos em que o deck está apenas incompleto
- combina cores de condição, erro, primary, cards inválidos e destaques no mesmo contexto

Diagnóstico:

- maior risco de semântica visual incorreta no core do produto

Direção:

- criar estado vazio/inicial próprio para deck novo
- esconder alertas severos até existir base mínima de deck
- usar neutro + um acento principal no estado “comece aqui”

### `app/lib/features/decks/screens/deck_import_screen.dart`

Problema:

- sucesso, aviso, erro e resumo convivem com muitos realces na mesma sequência
- há risco de dialog/resultado parecer mais “painel de status” do que fluxo orientado

Direção:

- consolidar visual do resultado em uma narrativa por prioridade:
  1. principal
  2. secundária
  3. detalhes

## Prioridade P1

### `app/lib/features/home/home_screen.dart`

Problema:

- muitos CTAs com cores diferentes lado a lado
- hero, ações rápidas, stats e cards usam vários acentos concorrentes

Diagnóstico:

- visual atraente, mas com excesso de estímulo por bloco

Direção:

- reduzir quantidade de botões coloridos simultâneos
- deixar um CTA dominante e ações secundárias mais neutras
- reservar `success/error/gold/soft` para uso contextual, não ornamental

### `app/lib/features/auth/screens/login_screen.dart`
### `app/lib/features/auth/screens/register_screen.dart`
### `app/lib/features/auth/screens/splash_screen.dart`

Problema:

- hero gradient + glow + branco puro + `primary/secondary` ao mesmo tempo

Diagnóstico:

- coerente com branding, mas um pouco mais intenso do que precisa

Direção:

- manter a identidade, mas reduzir brilho e número de camadas de destaque

### `app/lib/features/scanner/widgets/scanned_card_preview.dart`

Problema:

- preview combina:
  - raridade
  - confiança
  - condição
  - foil
  - edição
  - imagem

Diagnóstico:

- muita informação cromática simultânea em uma tela já naturalmente carregada

Direção:

- uma cor dominante por vez
- confiança e condição não devem competir com imagem e nome

## Prioridade P2

### `app/lib/features/community/screens/community_screen.dart`

Problema:

- não há hardcode agressivo, mas o volume de `AppTheme.*` e alpha é alto
- risco de excesso de micro-variações entre abas, chips e cards

Direção:

- simplificar o sistema de superfícies e reduzir variações de alpha/chips

### `app/lib/features/home/life_counter_screen.dart`

Problema:

- a tela usa várias cores fortes por definição de domínio

Diagnóstico:

- aqui o excesso é em parte intencional, porque é uma mesa multiplayer
- mesmo assim, ainda há risco de alguns controles pequenos competirem com os quadrantes

Direção:

- preservar a natureza colorida
- reduzir ruído dos controles secundários

## Telas relativamente saudáveis

Estas telas parecem mais controladas hoje:

- `app/lib/core/widgets/app_state_panel.dart`
- `app/lib/features/messages/screens/message_inbox_screen.dart`
- `app/lib/features/messages/screens/chat_screen.dart`
- `app/lib/features/notifications/screens/notification_screen.dart`
- parte da camada nova de widgets de deck extraída do `deck_details`

## Ranking bruto por densidade de cor/sinal

Levantamento estático dos arquivos mais “carregados”:

1. `app/lib/features/community/screens/community_screen.dart`
2. `app/lib/features/home/life_counter_screen.dart`
3. `app/lib/features/social/screens/user_profile_screen.dart`
4. `app/lib/features/binder/widgets/binder_item_editor.dart`
5. `app/lib/features/scanner/widgets/scanned_card_preview.dart`
6. `app/lib/features/trades/screens/trade_detail_screen.dart`
7. `app/lib/features/trades/screens/create_trade_screen.dart`
8. `app/lib/features/home/home_screen.dart`
9. `app/lib/features/binder/screens/binder_screen.dart`
10. `app/lib/features/market/screens/market_screen.dart`

Observação:

- densidade alta não significa automaticamente problema
- `life_counter_screen.dart`, por exemplo, tem alta densidade cromática por natureza funcional
- o problema real é quando a cor deixa de informar e passa só a disputar atenção

## Problemas sistêmicos detectados

### 1. Relatório antigo de cores parcialmente defasado

`app/RELATORIO_CORES_TEMAS.md` parece refletir uma versão anterior do tema em alguns pontos.

Impacto:

- risco de decisão em cima de contagem antiga

### 2. Budget declarado no tema não está sendo obedecido na prática

`app/lib/core/theme/app_theme.dart` define um orçamento de cor razoável.
Na prática, algumas telas ainda gastam cor além desse budget.

### 3. Semântica de vermelho precisa ser endurecida

O vermelho está correto para:

- erro real
- falha crítica
- validação bloqueante

Mas não deve ser dominante para:

- estado vazio
- construção inicial
- revisão opcional

## Backlog recomendado de correção

### Fase 1 — corrigir semântica do core

1. criar estado vazio dedicado para deck recém-criado em `deck_details`
2. adiar alertas pesados até o deck ter base mínima
3. reduzir vermelho e warning em fluxos iniciais

### Fase 2 — reduzir concorrência de CTA

1. simplificar `home_screen`
2. escolher um CTA dominante por viewport
3. neutralizar ações secundárias

### Fase 3 — limpar domínio visual contextual

1. reduzir simultaneidade entre condição, raridade, confiança e identidade
2. manter cores contextuais apenas onde agregam decisão

### Fase 4 — consolidar governança

1. regenerar `RELATORIO_CORES_TEMAS.md`
2. definir regra clara para:
   - `AppTheme.*`
   - `colorScheme.*`
   - proibição de `Color(0x...)` fora do tema, salvo exceção documentada

## Decisão recomendada

O próximo passo correto não é trocar a paleta.

O próximo passo correto é:

1. reduzir ruído visual do core de decks
2. separar estado vazio de estado de erro
3. diminuir o número de acentos simultâneos nas telas principais
4. só depois revisar superfícies secundárias

## Veredito final

O app não está “feio” por causa das cores.
Ele está, em alguns pontos, **colorido demais para a quantidade de hierarquia que entrega**.

Em resumo:

- a base do sistema é boa
- a aplicação está desigual
- o maior problema é semântica e concorrência visual
- o core de deck deve ser o primeiro alvo de limpeza
