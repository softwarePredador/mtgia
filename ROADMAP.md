# Roadmap de Produto — ManaLoom

Este documento é **estratégico**, não operacional.

Para prioridade diária, sequência de execução e decisões de escopo, usar:

- [docs/CONTEXTO_PRODUTO_ATUAL.md](docs/CONTEXTO_PRODUTO_ATUAL.md)

## Posição atual

O ManaLoom está sendo conduzido como produto `Commander-first`, com foco dominante no core de decks:

- criar
- importar
- analisar
- otimizar
- reconstruir quando necessário
- aplicar e validar

## Objetivo do ciclo atual

Transformar o fluxo principal de decks em uma jornada confiável o bastante para release, sem deixar features laterais diluírem a percepção de valor.

## Horizonte estratégico

### Horizonte 1 — Confiabilidade do core

Entregas esperadas:

- contrato estável de `generate -> analyze -> optimize -> rebuild -> validate`
- quality gates claros para legalidade, consistência e preservação de papel
- corpus estável de decks de referência
- smoke do app para a jornada principal

### Horizonte 2 — Clareza de produto

Entregas esperadas:

- UX do core de decks mais explicável
- feedback melhor de progresso, erro e sucesso
- análise de deck mais legível
- confiança maior no resultado da IA

### Horizonte 3 — Ecossistema que amplia retenção

Entregas esperadas:

- ligação entre deck, coleção e trade
- contador de vida forte para uso real de mesa
- instrumentação de uso e valor por módulo

## O que não deve competir com o core agora

Até o fluxo principal atingir confiança de release, ficam fora da frente dominante:

- expansão de community
- aprofundamento de trades fora do que ajuda o deck builder
- melhorias cosméticas desconectadas do fluxo principal
- features novas de scanner, market ou messages sem impacto no core

## Métricas estratégicas

- usuário conseguir chegar ao primeiro deck otimizado sem perder contexto
- regressão no core ser detectada por teste ou checklist
- suite local e gate principal permanecerem verdes
- resultados de IA serem explicáveis e aplicáveis

## Documentos de apoio

- índice da documentação ativa: [docs/README.md](docs/README.md)
- contexto operacional: [docs/CONTEXTO_PRODUTO_ATUAL.md](docs/CONTEXTO_PRODUTO_ATUAL.md)
- matriz de testes: [docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md](docs/MATRIZ_TESTES_OTIMIZACAO_2026-03-23.md)

## Nota importante

Roadmaps e trackers anteriores do app continuam úteis como apoio histórico, mas não definem mais a prioridade do repositório sem alinhamento explícito com o contexto operacional atual.
