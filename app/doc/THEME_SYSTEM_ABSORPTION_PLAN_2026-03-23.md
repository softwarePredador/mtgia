# Theme System Absorption Plan — 2026-03-23

## Objetivo

Registrar, de forma executável, o que o `ManaLoom` pode absorver do projeto `carMatch` em termos de arquitetura de tema, paleta, backgrounds e organização visual, sem descaracterizar a identidade do produto.

Comparação feita entre:

- `app/lib/core/theme/app_theme.dart`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/mobile/lib/core/theme/app_colors.dart`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/mobile/lib/core/theme/app_theme.dart`
- `/Users/desenvolvimentomobile/Documents/rafa/carMatch/mobile/lib/core/theme/figma_tokens.dart`

## Veredito

### O que o `carMatch` faz melhor

- separação entre tokens, cores e tema
- origem mais clara de design system
- maior previsibilidade de superfícies, bordas e botões
- backgrounds de auth mais sistematizados
- estrutura mais madura para manutenção

### O que o `ManaLoom` faz melhor

- fit visual real com produto de Magic
- paleta mais coerente com cartas como elemento principal
- semântica de domínio MTG integrada ao tema
- fundo neutro escuro que valoriza artwork e leitura de deck
- melhor relação entre identidade de produto e utilidade da interface

### Decisão

Nao migrar a identidade visual do `ManaLoom` para a estética do `carMatch`.

O caminho correto é:

- absorver a **arquitetura** do sistema de tema do `carMatch`
- manter a **paleta e a linguagem visual** do `ManaLoom`

## O que pode ser absorvido

### 1. Estrutura de design system

Absorver:

- separação entre:
  - `app_colors.dart`
  - `app_gradients.dart`
  - `app_typography.dart`
  - `app_theme.dart`
- camada de tokens base
- helpers claros para tema dark
- recipes reutilizáveis por contexto

Valor:

- reduz acoplamento do arquivo único atual
- facilita manutenção
- reduz hardcodes
- melhora previsibilidade visual

### 2. Organização de backgrounds

Absorver:

- backgrounds por contexto, não um único arquivo tentando servir tudo

Criar no `ManaLoom`:

- background de auth
- background de onboarding
- background de hero/home
- background de deck flow
- background de tabletop/life counter

Valor:

- deixa o app mais coeso
- evita exceções visuais espalhadas
- melhora sensação de produto fechado

### 3. Recipes de componentes visuais

Absorver o princípio, não a aparência:

- superfícies padronizadas
- bordas padronizadas
- níveis de elevação previsíveis
- estilos de CTA, secondary action e feedback states

Valor:

- app deixa de parecer soma de telas independentes
- reduz diferenças de maturidade entre módulos

### 4. Camada de tokens ligada a design

Absorver:

- ideia de tokens exportáveis/documentáveis
- separação entre token bruto e uso semântico

Nao significa:

- gerar automaticamente tudo do Figma agora
- nem introduzir centenas de tokens inúteis

Meta correta:

- poucos tokens
- bem nomeados
- ligados ao uso real do produto

## O que nao deve ser absorvido

### 1. Paleta principal do `carMatch`

Nao absorver:

- rose como cor principal
- indigo/rose como assinatura dominante
- clima visual mais “dating/marketplace genérico”

Motivo:

- piora o fit com Magic
- reduz destaque das cartas
- descaracteriza a identidade atual do `ManaLoom`

### 2. Estética de fundo como copia direta

Nao copiar:

- gradientes de auth do `carMatch` como estão
- composição visual pronta de outra marca

Motivo:

- referência externa pode orientar composição
- mas a solução final precisa continuar parecendo `ManaLoom`

### 3. Excesso de tokens

Nao importar:

- centenas de cores/tokens do `figma_tokens.dart`

Motivo:

- isso cria complexidade sem necessidade
- o projeto atual precisa de sistema enxuto, não de inflação de token

## Direção visual correta para o `ManaLoom`

### Manter

- `backgroundAbyss`
- `surfaceSlate`
- `surfaceElevated`
- `manaViolet`
- `primarySoft`
- `mythicGold`
- semântica WUBRG
- foco em neutral dark UI
- arte da carta como protagonista

### Evoluir

- menos dependência de um único arquivo de tema
- mais composição visual por contexto
- backgrounds mais intencionais
- superfícies e headers mais previsíveis
- menos hardcodes fora da camada de tema

## Arquitetura alvo recomendada

Criar ou migrar para algo próximo disso:

- `app/lib/core/theme/app_colors.dart`
- `app/lib/core/theme/app_gradients.dart`
- `app/lib/core/theme/app_typography.dart`
- `app/lib/core/theme/app_surfaces.dart`
- `app/lib/core/theme/app_theme.dart`

Opcional depois:

- `app/lib/core/theme/app_component_recipes.dart`

## Ordem correta de execução

Esta frente **nao entra antes do core de decks**.

Ela deve entrar somente depois de:

1. modularizar `server/routes/ai/optimize/index.dart`
2. transformar o corpus estável em gate recorrente
3. adicionar casos dirigidos do core
4. criar smoke do app para `deck details -> optimize -> apply -> validate`

So depois disso:

5. refatorar arquitetura do tema do app
6. criar sistema de backgrounds por contexto
7. limpar hardcodes restantes
8. revisar visual dos módulos com maior percepção

## Sequência executável dessa frente quando chegar a vez

### Etapa 1 — Extração de base

- mover cores base de `app_theme.dart` para `app_colors.dart`
- mover gradientes para `app_gradients.dart`
- mover tipografia para `app_typography.dart`

Critério de aceite:

- nenhum comportamento visual muda
- só reorganização estrutural

### Etapa 2 — Recipes de superfície

- criar helpers de:
  - panel
  - card
  - state container
  - hero block
  - bottom sheet chrome

Critério de aceite:

- telas começam a compartilhar estrutura visual real

### Etapa 3 — Backgrounds por contexto

- implementar backgrounds dedicados para:
  - auth
  - onboarding
  - home
  - decks
  - tabletop

Critério de aceite:

- sem copiar o `carMatch`
- mantendo linguagem própria do `ManaLoom`

### Etapa 4 — Limpeza final

- remover hardcodes residuais
- equalizar contraste e hierarquia
- revisar módulos mais fracos

## Critério de sucesso

Essa absorção só deve ser considerada bem sucedida quando:

1. o tema do `ManaLoom` ficar mais modular do que hoje
2. a identidade visual continuar claramente de MTG
3. o app não parecer “re-skin” do `carMatch`
4. backgrounds e superfícies ficarem mais consistentes
5. diminuir o número de hardcodes visuais fora da camada de tema

## Resumo executivo

O `carMatch` é melhor como **arquitetura de design system**.  
O `ManaLoom` é melhor como **linguagem visual para este produto**.

Portanto:

- copiar a paleta: **não**
- copiar a organização do sistema de tema: **sim**
- copiar o background pronto: **não**
- absorver a disciplina de tokens e recipes: **sim**
