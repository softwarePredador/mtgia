# Hermes Analysis: Product Direction

> Status atual: direcao de produto historica.
> Use como norte estrategico, nao como prova tecnica ou contrato de execucao.

> Direcao de produto do ManaLoom. Atualizado em 2026-05-26.

## O Produto

ManaLoom e uma plataforma **Commander-first** para Magic: The Gathering.
A promessa central: criar, importar, analisar, otimizar e validar decks com confiabilidade real.

## Fluxo carro-chefe

```
criar/importar → analisar → otimizar → aplicar → validar
```

O usuario deve conseguir sair do onboarding e chegar ao primeiro deck otimizado sem perder contexto.

## Jornada completa

1. **Onboarding** — escolhe formato (Commander, Brawl, etc.)
2. **Home** — ve seus decks, cria novo (IA por prompt) ou importa lista
3. **Abrir deck** — 3 abas: Visao Geral, Cartas, Analise
4. **Analisar** — IA analisa forcas/fraquezas + functional tags (ramp, draw, removal, wipes, protection)
5. **Otimizar** — IA sugere swaps, preview, apply parcial ou total
6. **Rebuild guiado** — se IA indica `needs_repair`, gera draft alternativo
7. **Validar** — legalidade, identidade de cor, bracket, regras Commander
8. **Compartilhar / Exportar** — para jogar ou trocar

## Funcionalidades complementares (bloqueadas ate core blindado)

- **Community** — decks publicos, seguir usuarios
- **Binder** — colecao pessoal com trade/sale
- **Marketplace** — compra/venda entre usuarios
- **Trades** — ofertas, status, chat, trust metrics
- **Messages** — mensagens diretas
- **Notifications** — badge, FCM real (Android PASS em 2026-05-11)
- **Life Counter** — mesa Commander (2p-6p) com poison, commander tax, high roll, D20
- **Scanner / OCR** — DEFERRED, fora do escopo atual

## Decisoes de produto recentes

| Decisao | Data | Status |
|---------|------|--------|
| Premium Visual System (tema global, golden tests, agente UX) | 2026-05-25 | **PASS** — 63 arquivos, commit massivo |
| Lotus life counter skin premium por jogador | 2026-05-25 | PASS_WITH_RISKS — main table em `master`; overlays/settings/card search exigem prova viva antes de baseline canonica |
| Splash art oficial (slasharat) | 2026-05-21 | PASS |
| App icon oficial (nrelogo) | 2026-05-21 | PASS |
| UX/UI global premium non-scanner | 2026-05-21 | PASS_WITH_RISKS |
| Semantic Layer v2 (build/optimize/generate) | 2026-05-18 | Shadow mode ativo |
| Functional Card Tags mass audit | 2026-05-18 | 66.6% cobertura |
| Deck Analysis consumindo functional_tags | 2026-05-18 | PASS |
| Localized import names (38.594 aliases PT) | 2026-05-18 | PASS |
| Internal release non-scanner QA | 2026-05-15 | PASS_WITH_RISKS |
| Commander Reference 24+ profiles | 2026-05-14 | PASS_WITH_RISKS |
| Realtime notifications + FCM Android | 2026-05-11 | PASS |
| Sentry backend validado | 2026-03-24 | PASS |
| Sentry mobile + x-request-id correlacao | 2026-03-24 | PENDENTE |
| Sprint 1 (blindar core de decks) | 2026-03-23 | ~95% fechada |

## Norte de qualidade (para declarar release confiavel)

1. Usuario sai do onboarding e chega ao primeiro deck otimizado sem perda de contexto
2. Backend responde com contratos previsiveis e suites verdes
3. Telas do fluxo core tem estados claros de loading, erro, vazio e sucesso
4. Resultados de IA sao explicaveis, aplicaveis e validaveis
5. Qualquer regressao no core e detectada por teste ou checklist

## Horizonte estrategico

- **H1 (atual):** Confiabilidade do core — contracts estaveis, quality gates, corpus de referencia
- **H2:** Clareza de produto — UX mais explicavel, feedback de IA, analise legivel
- **H3:** Ecossistema — ligacao deck-colecao-trade, life counter forte, instrumentacao de uso

## Fila oficial de execucao

1. Fechar residual de orquestracao em `deck_provider.dart`
2. Atualizar/validar a prova viva do Lotus life counter quando overlays/settings
   forem alterados
3. Validar ingestao real do Sentry mobile
4. Correlacao x-request-id ponta a ponta
5. Revisar CHECKLIST_GO_LIVE_FINAL.md com entregas reais
6. Sobre depois: carga basica/thresholds do fluxo core
7. So depois: frentes secundarias (community, binder, trades, scanner)
