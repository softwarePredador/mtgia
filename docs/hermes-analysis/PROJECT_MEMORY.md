# Hermes Analysis: Project Memory

> Memoria operacional inicial para o agente residente do projeto ManaLoom.

## Identidade do projeto

- Nome: ManaLoom
- Repositorio: `softwarePredador/mtgia`
- Produto: app e backend para Magic: The Gathering com foco em Commander
- Stack principal: Flutter no `app/` e Dart Frog no `server/`
- Estado inicial analisado pelo agente: branch `master`, commit `97195723`

## Regra principal

`docs/CONTEXTO_PRODUTO_ATUAL.md` e a fonte de verdade operacional. Se houver conflito entre roadmaps antigos, relatorios historicos e esse arquivo, o contexto atual vence.

## Objetivo do produto

Construir um fluxo confiavel para criar/importar decks, validar regras e identidade, analisar plano e problemas, otimizar ou reconstruir com IA, aplicar mudancas com controle e validar o resultado final.

## Arquitetura resumida

```text
app/ Flutter
  - Provider para estado
  - GoRouter para navegacao
  - Firebase/Sentry/MLKit/camera como dependencias nativas
  - core de decks em app/lib/features/decks

server/ Dart Frog
  - rotas REST por dominio
  - PostgreSQL
  - auth JWT/bcrypt
  - Sentry
  - integracoes de dados MTG e IA
  - core de IA em server/routes/ai e server/lib/ai
```

## Fontes canonicas para abrir qualquer analise

1. `docs/CONTEXTO_PRODUTO_ATUAL.md`
2. `docs/README.md`
3. `server/manual-de-instrucao.md`
4. `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
5. `app/doc/APP_AUDIT_2026-04-29.md`
6. `app/doc/UI_TEST_SURFACE_MAP.md`
7. `CHECKLIST_GO_LIVE_FINAL.md`
8. `git log --oneline --decorate -80`

## Comandos de referencia

```bash
./scripts/quality_gate.sh quick
./scripts/quality_gate.sh full
./scripts/quality_gate.sh resolution

cd server && dart test
cd app && flutter analyze --no-fatal-infos
cd app && flutter test
```

## Estado do agente no servidor

O Hermes atualmente consegue clonar, ler, resumir e auditar o repositorio. O ambiente do container nao possui Dart/Flutter, portanto a validacao automatica completa depende de toolchain externa ou instalacao futura.

## Politica de resposta do agente

Quando o usuario perguntar sobre o projeto, o agente deve consultar esta memoria, checar `docs/CONTEXTO_PRODUTO_ATUAL.md` para prioridade/escopo, checar commits recentes para estado atual, separar fato observado de inferencia e apontar riscos por arquivo ou area afetada.

## Areas criticas

- `app/lib/features/decks/**`
- `server/routes/ai/**`
- `server/lib/ai/**`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `scripts/quality_gate.sh`
- `CHECKLIST_GO_LIVE_FINAL.md`
