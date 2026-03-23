# Design, Color and Layout Audit — 2026-03-18

## Escopo

Auditoria de produto focada em:

- paleta de cores
- consistência visual
- agradabilidade estética
- clareza de layout
- maturidade visual por área do app

Base principal:

- `app/lib/core/theme/app_theme.dart`
- telas de auth, home, decks, coleção, trade e contador de vida

## Veredito geral

O app está visualmente **bom e coerente o suficiente para uso real**, mas ainda não está totalmente “fechado” em acabamento.

Nota geral de design:

- `7/10`

Leitura resumida:

- não está feio
- já tem identidade visual própria
- a paleta base é boa
- algumas áreas ainda parecem mais utilitárias do que produto premium

## Atualização após consolidação parcial

Desde esta auditoria, já foram aplicados ajustes concretos nesta frente:

- shell principal sem chrome duplicado
- correções de overflow nos pontos mais frágeis
- auth com painel central mais consistente visualmente
- home sem cores hardcoded nas quick actions principais
- contador de vida com melhor hierarquia, separação visual e sessão resumida
- notificações com cards mais legíveis e semântica de cor alinhada ao tema
- tela de última edição com header, estado de erro e lista mais coerentes com o restante do app
- semântica visual de MTG mais centralizada no tema
  - raridade
  - pips / símbolos de mana
- `card_detail`, `deck_card` e o header de `deck_details` com visual mais consistente

Isso melhora a nota prática do estado atual para algo mais próximo de:

- `7.5/10`

Atualização adicional dentro da frente de consistência:

- estados vazios e de erro começaram a convergir para um mesmo padrão visual
- isso já foi aplicado em:
  - notifications
  - messages
  - trade inbox
  - latest set collection
- contador de vida ganhou uma direção visual mais autoral:
  - medalhão central expansível
  - menos chrome tradicional
  - quadrantes mais imersivos e menos “cards genéricos”

Documento complementar para o contador de vida:

- `app/doc/LIFE_COUNTER_TABLETOP_UX_HANDOFF_2026-03-18.md`

Documento complementar para evolução estrutural do tema:

- `app/doc/THEME_SYSTEM_ABSORPTION_PLAN_2026-03-23.md`

## O que está forte

### 1. Paleta base

A paleta principal em `app/lib/core/theme/app_theme.dart` é boa:

- `backgroundAbyss`
- `surfaceSlate`
- `surfaceElevated`
- `manaViolet`
- `primarySoft`
- `mythicGold`

Essa combinação cria um visual escuro elegante, com:

- identidade MTG sem cair em clichê genérico
- bom destaque para arte das cartas
- hierarquia visual clara entre fundo, superfície e acento

### 2. Tipografia

O uso de `Inter` para corpo e `Crimson Pro` para títulos funciona bem para o produto:

- corpo moderno
- títulos com um pouco mais de personalidade

### 3. Home e Auth

As áreas mais agradáveis hoje são:

- `app/lib/features/home/home_screen.dart`
- `app/lib/features/auth/screens/login_screen.dart`
- `app/lib/features/auth/screens/register_screen.dart`

Elas têm:

- melhor direção visual
- melhor uso de gradiente
- CTAs mais fortes
- sensação mais clara de “produto”

## Onde a experiência ainda perde força

### 1. Cores hardcoded fora do tema

Apesar de o tema estar bem definido, ainda existem várias cores hardcoded fora de `AppTheme`.

Exemplos relevantes:

- `app/lib/features/home/home_screen.dart`
- `app/lib/features/auth/screens/login_screen.dart`
- `app/lib/features/auth/screens/register_screen.dart`
- `app/lib/features/home/life_counter_screen.dart`
- `app/lib/features/decks/screens/deck_details_screen.dart`

Impacto:

- aumenta risco de deriva visual
- dificulta manutenção da identidade
- faz algumas telas parecerem de sistemas visuais levemente diferentes

### 2. Inconsistência entre telas “premium” e telas “utilitárias”

Algumas telas parecem muito mais cuidadas do que outras.

Mais fortes:

- Home
- Login
- Register
- algumas partes de Decks

Mais utilitárias:

- onboarding
- latest set
- algumas telas de trade
- contador de vida

Impacto:

- o app alterna entre “produto de marca” e “ferramenta interna bem arrumada”

### 3. Excesso de dependência em roxo + dourado como única assinatura

A base é boa, mas o sistema ainda depende muito de:

- roxo para CTA
- dourado para destaque

Isso funciona, mas pode ficar repetitivo sem mais variações sutis de composição:

- diferentes superfícies
- blocos com hierarquia mais clara
- seções mais distintas

## Auditoria por área

### Auth

Status:

- visualmente forte

Pontos positivos:

- gradiente agradável
- logo com glow funciona
- título com boa presença

Pontos a melhorar:

- a tela de cadastro está boa, mas ainda um pouco longa e densa
- helper texts competem um pouco com a limpeza do layout

### Home

Status:

- é hoje a tela mais convincente do app

Pontos positivos:

- CTA principal é claro
- ações rápidas são úteis
- sensação de “hub” bem resolvida

Pontos a melhorar:

- ainda dá para refinar agrupamento visual das quick actions
- poderia haver um pouco mais de hierarquia entre “ação principal” e “atalhos secundários”

### Decks

Status:

- funcionalmente forte
- visualmente mais consistente após a consolidação desta rodada, mas ainda carregada em alguns momentos

Pontos positivos:

- o fluxo de optimize tem valor real
- a interface já comunica profundidade
- o header principal do deck está mais próximo do nível visual de Home/Auth
- `deck_card` e `card_detail` agora compartilham semântica visual melhor com o tema

Pontos a melhorar:

- alguns diálogos e sheets são densos demais
- a parte de “antes vs depois” ainda parece mais painel técnico do que experiência refinada

### Coleção / Marketplace / Trades

Status:

- úteis
- visualmente menos maduros que Home/Auth

Pontos positivos:

- coerência funcional
- boa base para um ecossistema

Pontos a melhorar:

- mais sensação de valor comercial/troca
- mais refinamento de densidade, espaçamento e agrupamento de informação
- telas ainda bastante orientadas a formulário/lista

### Contador de vida

Status:

- tecnicamente competente
- visualmente funcional
- produto ainda simples demais para mesa de Commander

Atualização:

- a ergonomia de mesa passou a ser tratada como requisito explícito
- os controles críticos foram movidos para zona neutra
- o contador agora tem uma direção de UX mais próxima de ferramenta de mesa real

Pontos positivos:

- legível
- painel por jogador é claro
- counters em sheet estão organizados

Pontos fracos:

- pouca personalidade visual
- pouca profundidade de recursos
- falta sensação de ferramenta de mesa realmente robusta

Veredito:

- não está mal feito
- está subdimensionado para a expectativa de um jogador de Commander

## O que realmente precisa ser ajustado

### Prioridade alta

1. Centralizar melhor as cores

- reduzir hardcodes fora de `AppTheme`
- transformar cores recorrentes em tokens ou helpers claros

2. Equalizar o nível visual entre módulos

- onboarding
- latest set
- trade
- contador de vida

3. Refinar a densidade das telas de deck/trade

- menos sensação de painel técnico cru
- mais agrupamento visual por bloco

### Prioridade média

1. Padronizar melhor headers de tela

- hoje algumas telas parecem pertencer ao mesmo produto e outras menos

2. Criar componentes visuais mais consistentes

- hero section
- section header
- badges
- cards de resumo
- estados vazios

3. Diminuir dependência de acentos fortes o tempo todo

- usar mais superfície, tipografia e contraste estrutural
- não depender só do roxo para parecer “bonito”

### Prioridade baixa

1. Micro-refinamentos de sombras, glow e motion
2. Variação visual mais rica em empty states
3. Melhor acabamento em alguns ícones/estados auxiliares

## Recomendação prática

Se a equipe for mexer nisso agora, a ordem mais eficiente é:

1. limpar hardcoded colors fora do tema
2. padronizar headers e containers
3. redesenhar visualmente o contador de vida
4. refinar optimize/deck details
5. só depois mexer em telas menores

## Conclusão

O visual do app já é agradável e coerente o suficiente para produto real.  
O problema não é “o design está feio”. O problema é:

- ainda falta consistência total
- algumas áreas estão mais maduras do que outras
- o contador de vida e telas utilitárias ainda estão abaixo do melhor nível do app

Em resumo:

- **não precisa de redesign completo**
- **precisa de consolidação visual**
- **vale ajustar antes de expandir muito o produto**
