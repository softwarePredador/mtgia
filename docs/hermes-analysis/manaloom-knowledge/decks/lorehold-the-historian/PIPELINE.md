# Lorehold Knowledge Pipeline — Logs

> Pipeline de 4 agentes para aprendizado continuo do deck Lorehold.
> Iniciado em 2026-05-27.

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                    LOREHOLD KNOWLEDGE PIPELINE                    │
│                                                                  │
│  Agent 1 (30min)   Agent 2 (60min)   Agent 3 (120min)            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Deck Scout   │  │ Validator    │  │ Mulligan     │           │
│  │              │  │              │  │ Analyst      │           │
│  │ Busca decks  │  │ Metricas vs  │  │ Simulacao de │           │
│  │ reais na web │  │ EDHREC       │  │ 1000 maos    │           │
│  │ EDHREC,      │  │ profile      │  │              │           │
│  │ Moxfield,    │  │              │  │ Taxa de      │           │
│  │ Reddit       │  │ Gaps,        │  │ mulligan,    │           │
│  │              │  │ alertas      │  │ consistencia │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                 │                 │                    │
│         └────────────┬────┴────────────────┘                     │
│                      ▼                                           │
│           ┌──────────────────┐                                   │
│           │ Agent 4 (6h)     │                                   │
│           │ Evolution Oracle │                                   │
│           │                  │                                   │
│           │ Le os 3 logs     │                                   │
│           │ Propoe mudancas  │                                   │
│           │ Aplica (max 3)   │                                   │
│           │ Documenta        │                                   │
│           └──────────────────┘                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Agent Jobs

| ID | Nome | Schedule | Função |
|:---|:-----|:--------:|:-------|
| f20ac299992b | lorehold-deck-scout | 30min | Buscar decks reais de Lorehold |
| 712579b15767 | lorehold-deck-validator | 60min | Validar metricas vs EDHREC |
| 08468451a06a | lorehold-mulligan-analyst | 120min | Simular mulligans |
| a50bef4c2a59 | lorehold-evolution-oracle | 6h | Aprender e evoluir o deck |

## Log Files

- `SCOUT_LOG.md` — descobertas de decks externos
- `VALIDATOR_LOG.md` — metricas do deck vs EDHREC
- `MULLIGAN_LOG.md` — analise de consistencia
- `EVOLUTION_LOG.md` — historico de mudancas e aprendizado