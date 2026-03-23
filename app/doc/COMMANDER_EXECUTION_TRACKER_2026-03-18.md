# Commander Execution Tracker — 2026-03-18

> Tracker historico/complementar do app.
> Desde `2026-03-23`, a ordem operacional principal do projeto e definida por `docs/CONTEXTO_PRODUTO_ATUAL.md`.
> Este arquivo continua util para backlog e memoria de execucao das frentes de app, mas nao substitui a prioridade atual do core de decks.

## Objetivo

Transformar o roadmap em uma fila executável, com status claro, ordem de trabalho e andamento atual.

## Legenda de status

- `DONE`: entregue e validado
- `IN_PROGRESS`: frente ativa atual
- `QUEUED`: próximo na fila
- `BLOCKED`: depende de dados, decisão externa ou massa crítica

## Frente ativa atual

`IN_PROGRESS`

- `APP-UI-04` — limpeza fina de hardcodes e estados secundários
  - contraste, headers secundários e empty states
  - objetivo: fechar a consistência visual nos fluxos menos nobres do app

## Ordem operacional

1. fechar `APP-UI-04`
2. depois avançar `APP-BINDER-01`
3. depois avançar `APP-BINDER-02`
4. depois avançar `APP-LIFE-03`
5. em paralelo oportunista, continuar `SERVER-OPT-03` quando houver decks novos

## Tracker por frente

| ID | Frente | Task | Status | Observação |
|---|---|---|---|---|
| SERVER-OPT-01 | Optimize / rebuild | Gate de resolução fim a fim estabilizado | DONE | runner principal validado com suíte real |
| SERVER-OPT-02 | Optimize / rebuild | Corpus expandido para 10 decks | DONE | baseline atual congelada |
| SERVER-OPT-03 | Optimize / rebuild | Expandir corpus para 15-20 decks | BLOCKED | depende de mais decks reais variados |
| APP-DECK-01 | Loop de deck | Estados `optimized / rebuild / safe_no_change` claros no app | DONE | fluxo automático já implementado |
| APP-DECK-02 | Loop de deck | Preview de optimize mais legível | DONE | menos painel técnico |
| APP-DECK-03 | Loop de deck | Loading de optimize / rebuild com etapas e dicas | DONE | etapa humanizada, barra, dicas rotativas |
| APP-DECK-04 | Loop de deck | Diagnóstico rápido na visão geral do deck | DONE | terrenos, ramp, compra, interação, wipes, CMC médio |
| APP-DECK-05 | Loop de deck | Playtest leve integrado ao fluxo principal | DONE | sample hand compacta na visão geral, mulligan e leitura rápida de keep |
| APP-DECK-06 | Loop de deck | Estados secundários e diálogos utilitários de deck refinados | DONE | generate/import/details agora usam feedback e dialogs mais consistentes |
| APP-DECK-07 | Loop de deck | Alternativas por slot e histórico de otimizações | QUEUED | depois de playtest e clareza de fluxo |
| APP-UI-01 | Visual / layout | Duplicidade estrutural do shell removida | DONE | base visual estabilizada |
| APP-UI-02 | Visual / layout | Overflows críticos corrigidos | DONE | marketplace, social, onboarding e trades |
| APP-UI-03 | Visual / layout | Consolidação visual principal em auth/home/decks/life counter | DONE | AppTheme e módulos principais alinhados |
| APP-UI-04 | Visual / layout | Limpeza fina de hardcodes e estados secundários | IN_PROGRESS | contraste, headers secundários, empty states |
| APP-LIFE-01 | Contador de vida | Ergonomia de mesa e hub central | DONE | controles centrais, rotação, toque melhor |
| APP-LIFE-02 | Contador de vida | Ferramentas de Commander na mesa | DONE | tax, casts, +5/-5, storm, monarch, initiative, d20 |
| APP-LIFE-04 | Contador de vida | Identidade visual própria da mesa | DONE | hub expansível, sem AppBar e quadrantes imersivos sem copiar referência |
| APP-LIFE-03 | Contador de vida | Presets e suporte avançado de variantes | QUEUED | partner, formatos, refinamentos opcionais |
| APP-BINDER-01 | Coleção / trade | Conectar deck ao binder | QUEUED | mostrar o que já possui e o que falta |
| APP-BINDER-02 | Coleção / trade | Matching útil de have/want | QUEUED | proposta de valor real para troca |
| APP-BINDER-03 | Coleção / trade | CTA direto do deck para compra/troca | QUEUED | depende do binder conectado |
| APP-METRIC-01 | Produto | Instrumentação de uso real dos fluxos | QUEUED | optimize, rebuild, safe-no-change, playtest, life counter |

## Andamento resumido

### Já entregue

- optimize/rebuild com resolução coerente
- loading de otimização com progresso real e UX melhor
- diagnóstico rápido de deck na visão geral
- consolidação visual principal
- contador de vida em nível de uso real de mesa
- contador de vida com identidade visual própria e hub central expansível

### Em execução agora

- `APP-UI-04`
  - limpar hardcodes restantes e equalizar estados secundários
  - objetivo prático: reduzir sensação de módulos com maturidade diferente

### Próximas entregas sem depender de nova decisão

- `APP-BINDER-01`
- `APP-BINDER-02`
- `APP-LIFE-03`

## Critério de continuidade

Enquanto não houver redirecionamento, a execução segue esta lógica:

1. terminar o item `IN_PROGRESS`
2. puxar o primeiro `QUEUED` da ordem operacional
3. registrar a mudança de status neste tracker e no roadmap quando houver entrega relevante
