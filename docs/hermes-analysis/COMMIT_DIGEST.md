# Hermes Analysis: Commit Digest

> Acompanhamento continuo dos commits do ManaLoom.
> Atualizado em 2026-05-25.

## Estado atual

- Branch observada: `master`
- HEAD: `97195723 Use new ManaLoom home hero art`
- Branch de analise: `codex/hermes-analysis-docs`
- Backend publicado: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Ultimo SHA publicado confirmado em health: `dc53d092` (2026-05-15)

## Ondas de commit identificadas (HEAD~80)

### Onda 1 — UX Polishing (maio 2026, ~12 commits recentes)
Commits mais recentes focam em refinamento visual do app:
- `9719572` — Nova hero art da home
- `60401a3` — Polish da home screen (1404 linhas alteradas)
- `6215b87` — Splash art oficial (slasharat, telas cheias Android/iOS)
- `5f07b24` — App icon oficial (nrelogo, 45 arquivos alterados)
- `f3c502d` — UX premium non-scanner (15 arquivos: card search, deck list, messages, binder)
- `8646755` — Commander choice modal no add-card
- `42b8f60` — Deck list cards enriquecidos, estados parciais
- `542bc22` — Deck list screen redesign (769 linhas)
- `75bbc66` — Card search screen redesign (290 linhas)
- `68eb63d` — Deck and card management polish (4 arquivos, 1350+ linhas)

### Onda 2 — Semantic Layer v2 (abril-maio 2026, ~30 commits)
- Schema aditivo `card_semantic_tags_v2` (velocidade, eficiencia, confidence, reason code)
- Shadow mode no optimize, enforcement flag, scorecard corpora
- Qualidade: 33.435 linhas, 72.3% tagged, 0 regressions agregadas
- Documentacao: 6 relatorios (Track A-E + Final)

### Onda 3 — Functional Tags + Localized Import (maio 2026, ~15 commits)
- `server/lib/ai/functional_card_tags.dart` — 22 tags deterministicas
- Mass audit: 22.272/33.435 linhas tagged (66.6%)
- Deck Analysis UI consumindo `functional_tags` com fallback legado
- Nomes localizados PT-BR: 38.594 aliases sincronizados
- Testes: runtime proof iPhone 15 Simulator com localized_matches_count

### Onda 4 — Commander Reference (abril-maio 2026, ~50 commits)
- Sprints 2, 3, 4 de perfis de comandantes
- Secrets of Strixhaven: 10 profiles curados (Lorehold, Dina, Zimone etc.)
- Anchor 30: Batches A (Atraxa, Chulane, Kinnan…), B (Edgar, Miirym, Aesi…), C (Brago, Feather, Krenko…)
- 24+ comandantes promovidos com runtime proof
- Runtime proofs: SM A135M fisico + iPhone 15 Simulator
- Feather app runtime PASS (2026-05-15), Miirym Sprint 4 runtime PASS (2026-05-14)

### Onda 5 — Observabilidade + Infra (marco 2026)
- Sentry backend validado com event_id real
- x-request-id implementado e propagado no middleware
- GET /ready publicado (depois deprecado em favor de /health/ready)
- Runbook EasyPanel formalizado
- CHECKLIST_GO_LIVE_FINAL.md criado (mas desatualizado desde marco)

## Direcao do projeto pelos commits

1. **Convergencia para o core** — otimizacao, geracao, analise e validacao de decks
2. **Refinamento visual** — reducao de ruido, hierarquia clara, hero/artes proprias
3. **Qualidade de IA** — semantic tags, functional tags, Commander Reference profiles
4. **Observabilidade** — Sentry, x-request-id, health endpoints
5. **Produto global** — icon, splash, onboarding, estados vazio/erro/loading

## O que esta fora dos commits recentes

- Scanner/OCR — sem commits ativos (DEFERRED)
- Community expansion — sem commits significativos
- Trades/Binder — manutencao apenas, sem expansao
- Carga/thresholds — nao iniciado

## Como atualizar este digest

```bash
git fetch --all --prune
BASE=$(git rev-parse origin/codex/hermes-analysis-docs)
git log --oneline --decorate --stat $BASE..origin/master
```

Comparar com a base anterior e classificar novos commits nas ondas acima.
Se uma nova onda emergir, adicionar categoria.
Se a direcao do projeto mudar, atualizar este arquivo e os demais `docs/hermes-analysis/*`.